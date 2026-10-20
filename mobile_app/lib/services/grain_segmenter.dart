// lib/services/grain_segmenter.dart
//
// On-device MobileSAM grain segmenter (Phase B).
// All heavy work is executed off the UI thread inside a Dart Isolate via
// Flutter's `compute()` helper.  Only typed lists (Float32List, Uint8List, ...)
// are transferred across isolate boundaries.
//
// Algorithm overview:
//   a. Decode image, bake EXIF orientation.
//   b. Make a WORK copy (long side 1024) and a CROP SOURCE (long side 2400).
//   c. Run SAM encoder once on the WORK copy -> image_embeddings.
//   d. Grain-finder on WORK copy: background subtraction -> diff+sat mask ->
//      morphology open/close -> connected components.
//   e. For each kept blob: decode with SAM, sanity check, retry with box prompt.
//   f. Crop from CROP SOURCE with white background fill -> PNG.
//   g. Release tensors and sessions properly.

/*import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime_plus/onnxruntime_plus.dart';

import '../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Public data model
// ---------------------------------------------------------------------------

/// One successfully segmented grain crop (coordinates in the CROP SOURCE).
class GrainCrop {
  final Uint8List pngBytes;
  final int x;
  final int y;
  final int w;
  final int h;

  const GrainCrop({
    required this.pngBytes,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

class SegmentationReport {
  final int originalWidth;
  final int originalHeight;
  final int rawComponents;
  final int usableGrains;
  final int touchingBlobs;
  final int skippedGrains;
  final bool grainCapReached;
  final double sharpness;

  const SegmentationReport({
    required this.originalWidth,
    required this.originalHeight,
    required this.rawComponents,
    required this.usableGrains,
    required this.touchingBlobs,
    required this.skippedGrains,
    required this.grainCapReached,
    required this.sharpness,
  });
}

// ---------------------------------------------------------------------------
// Internal isolate message types (only primitives / typed lists)
// ---------------------------------------------------------------------------

class _SegmentRequest {
  final Uint8List imageBytes;
  final Uint8List encoderModelBytes;
  final Uint8List decoderModelBytes;

  const _SegmentRequest({
    required this.imageBytes,
    required this.encoderModelBytes,
    required this.decoderModelBytes,
  });
}

class _GrainCropData {
  final Uint8List pngBytes;
  final int x, y, w, h;
  const _GrainCropData(this.pngBytes, this.x, this.y, this.w, this.h);
}

class _SegmentationResult {
  final List<_GrainCropData> crops;
  final SegmentationReport report;

  const _SegmentationResult(this.crops, this.report);
}

// ---------------------------------------------------------------------------
// GrainSegmenter -- public API
// ---------------------------------------------------------------------------

class GrainSegmenter {
  Uint8List? _encoderBytes;
  Uint8List? _decoderBytes;
  bool _initialized = false;
  SegmentationReport? lastReport;

  /// Load model bytes from assets. Must be called before [segment].
  Future<void> init() async {
    final t0 = DateTime.now();
    final encData = await rootBundle.load(AppConstants.samEncoderPath);
    _encoderBytes = encData.buffer.asUint8List();
    final decData = await rootBundle.load(AppConstants.samDecoderPath);
    _decoderBytes = decData.buffer.asUint8List();
    _initialized = true;
    final ms = DateTime.now().difference(t0).inMilliseconds;
    debugPrint('[GrainSegmenter] init: loaded encoder '
        '(${(_encoderBytes!.length / 1024).round()} KB) + decoder '
        '(${(_decoderBytes!.length / 1024).round()} KB) in ${ms}ms');
  }

  /// Segment grains in [imageBytes] (raw file bytes, any common image format).
  /// [onProgress] is called with a message string after each major stage.
  Future<List<GrainCrop>> segment(
    Uint8List imageBytes, {
    void Function(String stage)? onProgress,
  }) async {
    if (!_initialized) {
      throw StateError('GrainSegmenter.init() must be called before segment()');
    }

    onProgress?.call('Preparing');
    final t0 = DateTime.now();

    final request = _SegmentRequest(
      imageBytes: imageBytes,
      encoderModelBytes: _encoderBytes!,
      decoderModelBytes: _decoderBytes!,
    );

    // Run everything in a separate isolate so the UI thread is never blocked.
    final result = await compute(_segmentIsolate, request);
    lastReport = result.report;

    final totalMs = DateTime.now().difference(t0).inMilliseconds;
    debugPrint('[GrainSegmenter] segment: total wall-time ${totalMs}ms, '
        '${result.crops.length} grains returned sharpness=${result.report.sharpness}');

    return result.crops
        .map((d) => GrainCrop(
              pngBytes: d.pngBytes,
              x: d.x,
              y: d.y,
              w: d.w,
              h: d.h,
            ))
        .toList();
  }

  /// Release resources.
  void dispose() {
    _encoderBytes = null;
    _decoderBytes = null;
    _initialized = false;
    lastReport = null;
  }
}

// ---------------------------------------------------------------------------
// Isolate entry-point (top-level so compute() can send it)
// ---------------------------------------------------------------------------

Future<_SegmentationResult> _segmentIsolate(_SegmentRequest req) async {
  // Init ORT environment once per isolate invocation.
  OrtEnv.instance.init();
  try {
    return await _runSegmentation(req);
  } finally {
    OrtEnv.instance.release();
  }
}

Future<_SegmentationResult> _runSegmentation(_SegmentRequest req) async {
  // -- STAGE A: decode + bake EXIF -----------------------------------------
  final stageA = Stopwatch()..start();
  img.Image? fullImage = img.decodeImage(req.imageBytes);
  if (fullImage == null) throw Exception('GrainSegmenter: cannot decode image');
  // img.decodeImage handles EXIF orientation for JPEG automatically.
  stageA.stop();
  debugPrint('[GrainSegmenter] A decode: ${stageA.elapsedMilliseconds}ms  '
      '${fullImage.width}x${fullImage.height}');

  // -- STAGE B: make WORK (1024 long-side) and CROP SOURCE (2400) ----------
  final stageB = Stopwatch()..start();
  final workImg = _resizeLongSide(fullImage, AppConstants.samSide);
  final cropImg = _resizeLongSide(fullImage, AppConstants.cropSourceMaxSide);
  fullImage = null; // release full-res ASAP
  final workW = workImg.width;
  final workH = workImg.height;
  final cropW = cropImg.width;
  stageB.stop();
  debugPrint('[GrainSegmenter] B resize: ${stageB.elapsedMilliseconds}ms  '
      'WORK=${workW}x${workH}  CROP=${cropImg.width}x${cropImg.height}');

  // -- STAGE C: SAM encoder ------------------------------------------------
  final stageC = Stopwatch()..start();
  final sessionOpts = OrtSessionOptions();
  final encoderSession =
      OrtSession.fromBuffer(req.encoderModelBytes, sessionOpts);

  // Build [1,3,1024,1024] NCHW float32 tensor (zero-padded at top-left)
  final encInput = _buildEncoderTensor(workImg, workW, workH);
  final encInputOrt = OrtValueTensor.createTensorWithDataList(
      encInput, [1, 3, AppConstants.samSide, AppConstants.samSide]);
  final encRunOpts = OrtRunOptions();
  final encOutputs = await encoderSession
      .runAsync(encRunOpts, {'input_image': encInputOrt});
  encInputOrt.release();
  encRunOpts.release();
  encoderSession.release();

  // image_embeddings is the first (and only) output
  final embeddingOrt = encOutputs![0]!;
  final embedFlat = _flattenToFloat32(embeddingOrt.value);
  final embedShape = _inferEmbedShape(embeddingOrt.value);
  embeddingOrt.release();
  stageC.stop();
  debugPrint('[GrainSegmenter] C encoder: ${stageC.elapsedMilliseconds}ms');

  // -- STAGE D: grain finder on WORK copy ----------------------------------
  final stageD = Stopwatch()..start();
  final blobs = _findGrainBlobs(workImg, workW, workH);
  stageD.stop();
  debugPrint('[GrainSegmenter] D grain-finder: ${stageD.elapsedMilliseconds}ms  '
      'blobs found=${blobs.length}');

  if (blobs.isEmpty) return [];

  // -- STAGE E+F: per-grain SAM decode -> crop -----------------------------
  final decoderSession =
      OrtSession.fromBuffer(req.decoderModelBytes, OrtSessionOptions());

  final results = <_GrainCropData>[];
  final stageEF = Stopwatch()..start();

  for (int bi = 0; bi < blobs.length; bi++) {
    final blob = blobs[bi];
    final crop = await _decodeGrainWithSAM(
      decoderSession: decoderSession,
      embedFlat: embedFlat,
      embedShape: embedShape,
      workImg: workImg,
      cropImg: cropImg,
      blob: blob,
      workW: workW,
      workH: workH,
      cropW: cropW,
      blobIndex: bi,
    );
    if (crop != null) results.add(crop);
  }

  stageEF.stop();
  debugPrint('[GrainSegmenter] E+F decode+crop: ${stageEF.elapsedMilliseconds}ms  '
      'kept=${results.length}/${blobs.length}');

  // -- STAGE G: release sessions -------------------------------------------
  decoderSession.release();

  return results;
}

// ---------------------------------------------------------------------------
// Helper: resize long side with area (box) interpolation
// ---------------------------------------------------------------------------

img.Image _resizeLongSide(img.Image src, int longSide) {
  final longSrc = math.max(src.width, src.height);
  if (longSrc <= longSide) return src;
  final scale = longSide / longSrc;
  final newW = (src.width * scale).round();
  final newH = (src.height * scale).round();
  return img.copyResize(src,
      width: newW, height: newH, interpolation: img.Interpolation.average);
}

double _calculateTileSharpness(img.Image work) {
  final gray = Uint8List(work.width * work.height);
  for (var y = 0; y < work.height; y++) {
    for (var x = 0; x < work.width; x++) {
      final px = work.getPixel(x, y);
      gray[y * work.width + x] =
          (0.299 * px.r + 0.587 * px.g + 0.114 * px.b).round().clamp(0, 255);
    }
  }
  var maximum = 0.0;
  for (var ty = 0; ty < 6; ty++) {
    for (var tx = 0; tx < 6; tx++) {
      final x0 = (work.width * tx ~/ 6).clamp(1, work.width - 2);
      final x1 = (work.width * (tx + 1) ~/ 6).clamp(x0 + 1, work.width - 1);
      final y0 = (work.height * ty ~/ 6).clamp(1, work.height - 2);
      final y1 = (work.height * (ty + 1) ~/ 6).clamp(y0 + 1, work.height - 1);
      final values = <double>[];
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = y * work.width + x;
          values.add((4 * gray[i] -
                  gray[i - work.width] -
                  gray[i + work.width] -
                  gray[i - 1] -
                  gray[i + 1])
              .toDouble());
        }
      }
      if (values.isEmpty) continue;
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              values.length;
      if (variance > maximum) maximum = variance;
    }
  }
  return maximum;
}

// ---------------------------------------------------------------------------
// Helper: build SAM encoder input tensor (NCHW float32, 1x3x1024x1024)
// ---------------------------------------------------------------------------

Float32List _buildEncoderTensor(img.Image src, int w, int h) {
  const s = AppConstants.samSide;
  // SAM ImageNet normalisation constants
  const meanR = 123.675, meanG = 116.28, meanB = 103.53;
  const stdR = 58.395, stdG = 57.12, stdB = 57.375;

  final tensor = Float32List(1 * 3 * s * s); // zero-initialised (padding)
  const planeR = 0 * s * s;
  const planeG = 1 * s * s;
  const planeB = 2 * s * s;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final px = src.getPixel(x, y);
      final idx = y * s + x;
      tensor[planeR + idx] = (px.r.toDouble() - meanR) / stdR;
      tensor[planeG + idx] = (px.g.toDouble() - meanG) / stdG;
      tensor[planeB + idx] = (px.b.toDouble() - meanB) / stdB;
    }
  }
  return tensor;
}

// ---------------------------------------------------------------------------
// Helper: flatten nested ORT output value to Float32List
// ---------------------------------------------------------------------------

Float32List _flattenToFloat32(dynamic value) {
  if (value is Float32List) return value;
  if (value is List<double>) return Float32List.fromList(value);
  final buf = <double>[];
  void recurse(dynamic v) {
    if (v is double) {
      buf.add(v);
    } else if (v is List) {
      for (final item in v) recurse(item);
    }
  }
  recurse(value);
  return Float32List.fromList(buf);
}

/// Infer shape from nested list.
List<int> _inferEmbedShape(dynamic value) {
  final dims = <int>[];
  dynamic cur = value;
  while (cur is List) {
    dims.add((cur as List).length);
    cur = cur.isNotEmpty ? cur[0] : null;
  }
  return dims;
}

// ---------------------------------------------------------------------------
// Blob descriptor
// ---------------------------------------------------------------------------

class _Blob {
  final int x0, y0, x1, y1;
  final int area;
  const _Blob(this.x0, this.y0, this.x1, this.y1, this.area);
}

int _lastRawComponents = 0;
int _lastTouchingBlobs = 0;

int _lastRawComponents = 0;
int _lastTouchingBlobs = 0;

// ---------------------------------------------------------------------------
// Grain finder (on WORK copy)
// ---------------------------------------------------------------------------

List<_Blob> _findGrainBlobs(img.Image work, int w, int h) {
  // -- Gray + saturation channels --
  final gray = Uint8List(w * h);
  final sat = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final px = work.getPixel(x, y);
      final r = px.r.toDouble();
      final g = px.g.toDouble();
      final b = px.b.toDouble();
      gray[y * w + x] =
          (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
      final mx = math.max(r, math.max(g, b));
      final mn = math.min(r, math.min(g, b));
      sat[y * w + x] =
          (mx == 0 ? 0 : ((mx - mn) / mx * 255)).round().clamp(0, 255);
    }
  }

  // -- Background estimate: scale to 1/8, blur, scale back --
  // This replaces the Python 101x101 median blur cheaply.
  final bW = math.max(1, w ~/ 8);
  final bH = math.max(1, h ~/ 8);
  final smallGray = _scaleChannel(gray, w, h, bW, bH);
  final smallSat = _scaleChannel(sat, w, h, bW, bH);
  final blurGray = _boxBlur(smallGray, bW, bH, 3);
  final blurSat = _boxBlur(smallSat, bW, bH, 3);
  final bgGray = _scaleChannel(blurGray, bW, bH, w, h);
  final bgSat = _scaleChannel(blurSat, bW, bH, w, h);

  // -- Binary mask --
  final mask = Uint8List(w * h);
  final dt = AppConstants.diffThreshold;
  final st = AppConstants.satThreshold;
  for (int i = 0; i < w * h; i++) {
    final dg = (gray[i] - bgGray[i]).abs();
    final ds = (sat[i] - bgSat[i]).abs();
    mask[i] = (dg > dt || ds > st) ? 1 : 0;
  }

  // -- Morphological open 3x3, close 5x5 --
  final opened = _morphOpen(mask, w, h, 3);
  final closed = _morphClose(opened, w, h, 5);

  // -- Connected components (8-connectivity, union-find) --
  final labels = Int32List(w * h);
  final parent = <int>[];
  int nextLabel = 0;

  int find(int a) {
    while (parent[a] != a) {
      parent[a] = parent[parent[a]];
      a = parent[a];
    }
    return a;
  }

  void unite(int a, int b) {
    a = find(a);
    b = find(b);
    if (a != b) parent[b] = a;
  }

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = y * w + x;
      if (closed[i] == 0) {
        labels[i] = -1;
        continue;
      }
      final up = (y > 0) ? labels[(y - 1) * w + x] : -1;
      final left = (x > 0) ? labels[y * w + x - 1] : -1;
      final uleft = (y > 0 && x > 0) ? labels[(y - 1) * w + x - 1] : -1;
      final uright =
          (y > 0 && x < w - 1) ? labels[(y - 1) * w + x + 1] : -1;
      final neighbours =
          [up, left, uleft, uright].where((v) => v >= 0).toList();
      if (neighbours.isEmpty) {
        parent.add(nextLabel);
        labels[i] = nextLabel++;
      } else {
        final minLabel = neighbours.reduce(math.min);
        labels[i] = minLabel;
        for (final nb in neighbours) {
          if (nb != minLabel) unite(minLabel, nb);
        }
      }
    }
  }

  for (int i = 0; i < w * h; i++) {
    if (labels[i] >= 0) labels[i] = find(labels[i]);
  }

  // Compute bounding boxes and areas
  final bx0 = <int, int>{}, by0 = <int, int>{},
      bx1 = <int, int>{}, by1 = <int, int>{}, areas = <int, int>{};
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final lbl = labels[y * w + x];
      if (lbl < 0) continue;
      final a = areas[lbl] ?? 0;
      areas[lbl] = a + 1;
      if (a == 0) {
        bx0[lbl] = x; by0[lbl] = y; bx1[lbl] = x; by1[lbl] = y;
      } else {
        if (x < bx0[lbl]!) bx0[lbl] = x;
        if (y < by0[lbl]!) by0[lbl] = y;
        if (x > bx1[lbl]!) bx1[lbl] = x;
        if (y > by1[lbl]!) by1[lbl] = y;
      }
    }
  }

  final rawCount = areas.length;
  int aboveMax = 0;
  final blobs = <_Blob>[];
  for (final entry in areas.entries) {
    final area = entry.value;
    if (area > AppConstants.maxArea) { aboveMax++; continue; }
    if (area < AppConstants.minArea) continue;
    final lbl = entry.key;
    blobs.add(_Blob(bx0[lbl]!, by0[lbl]!, bx1[lbl]!, by1[lbl]!, area));
  }
  final usable = blobs.length;
  blobs.sort((a, b) => b.area.compareTo(a.area));
  if (blobs.length > AppConstants.maxGrains) blobs.length = AppConstants.maxGrains;

  debugPrint('[GrainSegmenter] D components: raw=$rawCount  '
      'usable=$usable  aboveMax=$aboveMax  kept=${blobs.length}');
  return blobs;
}

// ---------------------------------------------------------------------------
// Per-grain SAM decode
// ---------------------------------------------------------------------------

Future<_GrainCropData?> _decodeGrainWithSAM({
  required OrtSession decoderSession,
  required Float32List embedFlat,
  required List<int> embedShape,
  required img.Image workImg,
  required img.Image cropImg,
  required _Blob blob,
  required int workW,
  required int workH,
  required int cropW,
  required int blobIndex,
}) async {
  final pad = AppConstants.boxPad;
  final bx0 = math.max(0, blob.x0 - pad);
  final by0 = math.max(0, blob.y0 - pad);
  final bx1 = math.min(workW - 1, blob.x1 + pad);
  final by1 = math.min(workH - 1, blob.y1 + pad);
  final cx = (bx0 + bx1) / 2.0;
  final cy = (by0 + by1) / 2.0;

  // Centre-point prompt
  List<bool>? mask = await _runDecoder(
    session: decoderSession,
    embedFlat: embedFlat,
    embedShape: embedShape,
    workW: workW,
    workH: workH,
    pointCoords: [[cx, cy], [0.0, 0.0]],
    pointLabels: [1.0, -1.0],
    blobArea: blob.area,
    blobBx0: bx0, blobBy0: by0, blobBx1: bx1, blobBy1: by1,
  );

  // Sanity failed: retry with box prompt
  if (mask == null) {
    debugPrint('[GrainSegmenter] grain#$blobIndex: centre prompt failed sanity, '
        'retrying with box prompt');
    mask = await _runDecoder(
      session: decoderSession,
      embedFlat: embedFlat,
      embedShape: embedShape,
      workW: workW,
      workH: workH,
      pointCoords: [
        [bx0.toDouble(), by0.toDouble()],
        [bx1.toDouble(), by1.toDouble()],
      ],
      pointLabels: [2.0, 3.0],
      blobArea: blob.area,
      blobBx0: bx0, blobBy0: by0, blobBx1: bx1, blobBy1: by1,
    );
    if (mask == null) {
      debugPrint(
          '[GrainSegmenter] grain#$blobIndex: box prompt also failed -- skipping');
      return null;
    }
  }

  // Mask bounding box in WORK coordinates
  int mx0 = workW, my0 = workH, mx1 = 0, my1 = 0;
  for (int y = 0; y < workH; y++) {
    for (int x = 0; x < workW; x++) {
      if (mask[y * workW + x]) {
        if (x < mx0) mx0 = x;
        if (y < my0) my0 = y;
        if (x > mx1) mx1 = x;
        if (y > my1) my1 = y;
      }
    }
  }
  if (mx0 > mx1 || my0 > my1) return null;

  // Map to CROP SOURCE coordinates
  final ratio = cropW / workW;
  final cmx0 = (mx0 * ratio).floor();
  final cmy0 = (my0 * ratio).floor();
  final cmx1 = (mx1 * ratio).ceil();
  final cmy1 = (my1 * ratio).ceil();

  // Upsample mask to crop-source region (nearest-neighbour from work mask)
  final cropRW = cmx1 - cmx0 + 1;
  final cropRH = cmy1 - cmy0 + 1;
  final cropMask = List<bool>.filled(cropRW * cropRH, false);
  for (int cy2 = 0; cy2 < cropRH; cy2++) {
    for (int cx2 = 0; cx2 < cropRW; cx2++) {
      final wx = ((cmx0 + cx2) / ratio).round().clamp(0, workW - 1);
      final wy = ((cmy0 + cy2) / ratio).round().clamp(0, workH - 1);
      cropMask[cy2 * cropRW + cx2] = mask[wy * workW + wx];
    }
  }

  // Mask bbox in local crop coords
  int lmx0 = cropRW, lmy0 = cropRH, lmx1 = 0, lmy1 = 0;
  for (int y = 0; y < cropRH; y++) {
    for (int x = 0; x < cropRW; x++) {
      if (cropMask[y * cropRW + x]) {
        if (x < lmx0) lmx0 = x;
        if (y < lmy0) lmy0 = y;
        if (x > lmx1) lmx1 = x;
        if (y > lmy1) lmy1 = y;
      }
    }
  }

  final cpPad = AppConstants.cropPadPx;
  final cropH = cropImg.height;
  final finalX0 = math.max(0, cmx0 + lmx0 - cpPad);
  final finalY0 = math.max(0, cmy0 + lmy0 - cpPad);
  final finalX1 = math.min(cropImg.width - 1, cmx0 + lmx1 + cpPad);
  final finalY1 = math.min(cropH - 1, cmy0 + lmy1 + cpPad);
  final finalW = finalX1 - finalX0 + 1;
  final finalH = finalY1 - finalY0 + 1;
  if (finalW <= 0 || finalH <= 0) return null;

  // Cut rect from CROP SOURCE; fill non-mask pixels with white
  final outImg = img.Image(width: finalW, height: finalH);
  for (int y = 0; y < finalH; y++) {
    for (int x = 0; x < finalW; x++) {
      final sx = finalX0 + x;
      final sy = finalY0 + y;
      final lx = sx - cmx0;
      final ly = sy - cmy0;
      final inMask = (lx >= 0 && ly >= 0 && lx < cropRW && ly < cropRH)
          ? cropMask[ly * cropRW + lx]
          : false;
      if (inMask) {
        outImg.setPixel(x, y, cropImg.getPixel(sx, sy));
      } else {
        outImg.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
  }

  final pngBytes = Uint8List.fromList(img.encodePng(outImg));
  return _GrainCropData(pngBytes, finalX0, finalY0, finalW, finalH);
}

// ---------------------------------------------------------------------------
// SAM decoder call; returns boolean mask or null if sanity check fails
// ---------------------------------------------------------------------------

Future<List<bool>?> _runDecoder({
  required OrtSession session,
  required Float32List embedFlat,
  required List<int> embedShape,
  required int workW,
  required int workH,
  required List<List<double>> pointCoords,
  required List<double> pointLabels,
  required int blobArea,
  required int blobBx0,
  required int blobBy0,
  required int blobBx1,
  required int blobBy1,
}) async {
  final embedOrt =
      OrtValueTensor.createTensorWithDataList(embedFlat, embedShape);

  final coords = Float32List(4);
  coords[0] = pointCoords[0][0];
  coords[1] = pointCoords[0][1];
  coords[2] = pointCoords[1][0];
  coords[3] = pointCoords[1][1];
  final coordsOrt =
      OrtValueTensor.createTensorWithDataList(coords, [1, 2, 2]);

  final labelsArr = Float32List.fromList(pointLabels);
  final labelsOrt =
      OrtValueTensor.createTensorWithDataList(labelsArr, [1, 2]);

  final maskInput = Float32List(1 * 1 * 256 * 256);
  final maskInputOrt =
      OrtValueTensor.createTensorWithDataList(maskInput, [1, 1, 256, 256]);

  final hasMask = Float32List.fromList([0.0]);
  final hasMaskOrt =
      OrtValueTensor.createTensorWithDataList(hasMask, [1]);

  final origSize =
      Float32List.fromList([workH.toDouble(), workW.toDouble()]);
  final origSizeOrt =
      OrtValueTensor.createTensorWithDataList(origSize, [2]);

  final runOpts = OrtRunOptions();
  List<OrtValue?>? outputs;
  try {
    outputs = await session.runAsync(runOpts, {
      'image_embeddings': embedOrt,
      'point_coords': coordsOrt,
      'point_labels': labelsOrt,
      'mask_input': maskInputOrt,
      'has_mask_input': hasMaskOrt,
      'orig_im_size': origSizeOrt,
    });
  } catch (e) {
    debugPrint('[GrainSegmenter] decoder error: $e');
    return null;
  } finally {
    embedOrt.release();
    coordsOrt.release();
    labelsOrt.release();
    maskInputOrt.release();
    hasMaskOrt.release();
    origSizeOrt.release();
    runOpts.release();
  }

  final logitsRaw = _flattenToFloat32(outputs![0]!.value);
  for (final o in outputs) o?.release();

  final maskBool = List<bool>.generate(
      workH * workW, (i) => i < logitsRaw.length && logitsRaw[i] > 0);

  // Sanity: area ratio + overlap
  final maskArea = maskBool.where((v) => v).length;
  bool overlaps = false;
  outer:
  for (int y = blobBy0; y <= blobBy1; y++) {
    for (int x = blobBx0; x <= blobBx1; x++) {
      if (maskBool[y * workW + x]) { overlaps = true; break outer; }
    }
  }
  if (maskArea < blobArea * 0.5 || maskArea > blobArea * 2.5 || !overlaps) {
    return null;
  }
  return maskBool;
}

// ---------------------------------------------------------------------------
// Morphology helpers
// ---------------------------------------------------------------------------

Uint8List _morphErode(Uint8List src, int w, int h, int kSize) {
  final r = kSize ~/ 2;
  final dst = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool allOne = true;
      outer:
      for (int ky = -r; ky <= r; ky++) {
        for (int kx = -r; kx <= r; kx++) {
          final ny = y + ky, nx = x + kx;
          if (ny < 0 || ny >= h || nx < 0 || nx >= w || src[ny * w + nx] == 0) {
            allOne = false;
            break outer;
          }
        }
      }
      dst[y * w + x] = allOne ? 1 : 0;
    }
  }
  return dst;
}

Uint8List _morphDilate(Uint8List src, int w, int h, int kSize) {
  final r = kSize ~/ 2;
  final dst = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool anyOne = false;
      outer:
      for (int ky = -r; ky <= r; ky++) {
        for (int kx = -r; kx <= r; kx++) {
          final ny = y + ky, nx = x + kx;
          if (ny >= 0 && ny < h && nx >= 0 && nx < w && src[ny * w + nx] == 1) {
            anyOne = true;
            break outer;
          }
        }
      }
      dst[y * w + x] = anyOne ? 1 : 0;
    }
  }
  return dst;
}

Uint8List _morphOpen(Uint8List src, int w, int h, int kSize) =>
    _morphDilate(_morphErode(src, w, h, kSize), w, h, kSize);

Uint8List _morphClose(Uint8List src, int w, int h, int kSize) =>
    _morphErode(_morphDilate(src, w, h, kSize), w, h, kSize);

// ---------------------------------------------------------------------------
// Channel scale (nearest-neighbour) and box blur
// ---------------------------------------------------------------------------

Uint8List _scaleChannel(Uint8List src, int sw, int sh, int dw, int dh) {
  final dst = Uint8List(dw * dh);
  for (int y = 0; y < dh; y++) {
    for (int x = 0; x < dw; x++) {
      final sx = (x * sw / dw).round().clamp(0, sw - 1);
      final sy = (y * sh / dh).round().clamp(0, sh - 1);
      dst[y * dw + x] = src[sy * sw + sx];
    }
  }
  return dst;
}

Uint8List _boxBlur(Uint8List src, int w, int h, int passes) {
  Uint8List cur = src;
  for (int p = 0; p < passes; p++) {
    final dst = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int sum = 0, count = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final ny = y + ky, nx = x + kx;
            if (ny >= 0 && ny < h && nx >= 0 && nx < w) {
              sum += cur[ny * w + nx];
              count++;
            }
          }
        }
        dst[y * w + x] = (sum / count).round();
      }
    }
    cur = dst;
  }
  return cur;
}*/

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime_plus/onnxruntime_plus.dart';

import '../core/constants/app_constants.dart';

int _lastRawComponents = 0;
int _lastTouchingBlobs = 0;

class SegmentationReport {
  final int originalWidth;
  final int originalHeight;
  final int rawComponents;
  final int usableGrains;
  final int touchingBlobs;
  final int skippedGrains;
  final bool grainCapReached;
  final double sharpness;

  const SegmentationReport({
    required this.originalWidth,
    required this.originalHeight,
    required this.rawComponents,
    required this.usableGrains,
    required this.touchingBlobs,
    required this.skippedGrains,
    required this.grainCapReached,
    required this.sharpness,
  });
}

// ---------------------------------------------------------------------------
// Public data model
// ---------------------------------------------------------------------------

/// One successfully segmented grain crop (coordinates in the CROP SOURCE).
class GrainCrop {
  final Uint8List pngBytes;
  final int x;
  final int y;
  final int w;
  final int h;

  const GrainCrop({
    required this.pngBytes,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

// ---------------------------------------------------------------------------
// Internal isolate message types (only primitives / typed lists)
// ---------------------------------------------------------------------------

class _SegmentRequest {
  final Uint8List imageBytes;
  final Uint8List encoderModelBytes;
  final Uint8List decoderModelBytes;

  const _SegmentRequest({
    required this.imageBytes,
    required this.encoderModelBytes,
    required this.decoderModelBytes,
  });
}

class _GrainCropData {
  final Uint8List pngBytes;
  final int x, y, w, h;
  const _GrainCropData(this.pngBytes, this.x, this.y, this.w, this.h);
}

class _SegmentationResult {
  final List<_GrainCropData> crops;
  final SegmentationReport report;

  const _SegmentationResult(this.crops, this.report);
}

// ---------------------------------------------------------------------------
// GrainSegmenter -- public API
// ---------------------------------------------------------------------------

class GrainSegmenter {
  Uint8List? _encoderBytes;
  Uint8List? _decoderBytes;
  bool _initialized = false;
  SegmentationReport? lastReport;

  /// Load model bytes from assets. Must be called before [segment].
  Future<void> init() async {
    final t0 = DateTime.now();
    final encData = await rootBundle.load(AppConstants.samEncoderPath);
    _encoderBytes = encData.buffer.asUint8List();
    final decData = await rootBundle.load(AppConstants.samDecoderPath);
    _decoderBytes = decData.buffer.asUint8List();
    _initialized = true;
    final ms = DateTime.now().difference(t0).inMilliseconds;
    debugPrint('[GrainSegmenter] init: loaded encoder '
        '(${(_encoderBytes!.length / 1024).round()} KB) + decoder '
        '(${(_decoderBytes!.length / 1024).round()} KB) in ${ms}ms');
  }

  /// Segment grains in [imageBytes] (raw file bytes, any common image format).
  /// [onProgress] is called with a message string after each major stage.
  Future<List<GrainCrop>> segment(
    Uint8List imageBytes, {
    void Function(String stage)? onProgress,
  }) async {
    if (!_initialized) {
      throw StateError('GrainSegmenter.init() must be called before segment()');
    }

    onProgress?.call('Preparing');
    final t0 = DateTime.now();

    final request = _SegmentRequest(
      imageBytes: imageBytes,
      encoderModelBytes: _encoderBytes!,
      decoderModelBytes: _decoderBytes!,
    );

    // Run everything in a separate isolate so the UI thread is never blocked.
    final result = await compute(_segmentIsolate, request);
    lastReport = result.report;

    final totalMs = DateTime.now().difference(t0).inMilliseconds;
    debugPrint('[GrainSegmenter] segment: total wall-time ${totalMs}ms, '
        '${result.crops.length} grains returned sharpness=${result.report.sharpness}');

    return result.crops
        .map((d) => GrainCrop(
              pngBytes: d.pngBytes,
              x: d.x,
              y: d.y,
              w: d.w,
              h: d.h,
            ))
        .toList();
  }

  /// Release resources.
  void dispose() {
    _encoderBytes = null;
    _decoderBytes = null;
    _initialized = false;
    lastReport = null;
  }
}

// ---------------------------------------------------------------------------
// Isolate entry-point (top-level so compute() can send it)
// ---------------------------------------------------------------------------

Future<_SegmentationResult> _segmentIsolate(_SegmentRequest req) async {
  // Init ORT environment once per isolate invocation.
  OrtEnv.instance.init();
  try {
    return await _runSegmentation(req);
  } finally {
    OrtEnv.instance.release();
  }
}

Future<_SegmentationResult> _runSegmentation(_SegmentRequest req) async {
  // -- STAGE A: decode + bake EXIF -----------------------------------------
  final stageA = Stopwatch()..start();
  img.Image? decoded = img.decodeImage(req.imageBytes);
  if (decoded == null) throw Exception('GrainSegmenter: cannot decode image');
  // image 3.x does NOT apply EXIF orientation by itself, so bake it in here.
  img.Image? fullImage = img.bakeOrientation(decoded);
  final originalWidth = fullImage.width;
  final originalHeight = fullImage.height;
  decoded = null;
  stageA.stop();
  debugPrint('[GrainSegmenter] A decode: ${stageA.elapsedMilliseconds}ms  '
      '${fullImage.width}x${fullImage.height}');

  // -- STAGE B: make WORK (1024 long-side) and CROP SOURCE (2400) ----------
  final stageB = Stopwatch()..start();
  final workImg = _resizeLongSide(fullImage, AppConstants.samSide);
  final cropImg = _resizeLongSide(fullImage, AppConstants.cropSourceMaxSide);
  fullImage = null; // release full-res ASAP
  final workW = workImg.width;
  final workH = workImg.height;
  final cropW = cropImg.width;
  final sharpness = _calculateTileSharpness(workImg);
  stageB.stop();
  debugPrint('[GrainSegmenter] B resize: ${stageB.elapsedMilliseconds}ms  '
      'WORK=${workW}x${workH}  CROP=${cropImg.width}x${cropImg.height}');

  // -- STAGE C: SAM encoder ------------------------------------------------
  final stageC = Stopwatch()..start();
  final sessionOpts = OrtSessionOptions();
  final encoderSession =
      OrtSession.fromBuffer(req.encoderModelBytes, sessionOpts);

  // Build [1,3,1024,1024] NCHW float32 tensor (zero-padded at top-left)
  final encInput = _buildEncoderTensor(workImg, workW, workH);
  final encInputOrt = OrtValueTensor.createTensorWithDataList(
      encInput, [1, 3, AppConstants.samSide, AppConstants.samSide]);
  final encRunOpts = OrtRunOptions();
  final encOutputs = await encoderSession
      .runAsync(encRunOpts, {'input_image': encInputOrt});
  encInputOrt.release();
  encRunOpts.release();
  encoderSession.release();

  // image_embeddings is the first (and only) output
  final embeddingOrt = encOutputs![0]!;
  final embedFlat = _flattenToFloat32(embeddingOrt.value);
  final embedShape = _inferEmbedShape(embeddingOrt.value);
  embeddingOrt.release();
  stageC.stop();
  debugPrint('[GrainSegmenter] C encoder: ${stageC.elapsedMilliseconds}ms');

  // -- STAGE D: grain finder on WORK copy ----------------------------------
  final stageD = Stopwatch()..start();
  final blobs = _findGrainBlobs(workImg, workW, workH);
  stageD.stop();
  debugPrint('[GrainSegmenter] D grain-finder: ${stageD.elapsedMilliseconds}ms  '
      'blobs found=${blobs.length}');

  final touchingBlobs = _lastTouchingBlobs;
  final rawComponents = _lastRawComponents;
  final usableGrains = blobs.length;
  final grainCapReached = blobs.length >= AppConstants.maxGrains;
  if (blobs.isEmpty) {
    return _SegmentationResult(
      const [],
      SegmentationReport(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        rawComponents: rawComponents,
        usableGrains: 0,
        touchingBlobs: touchingBlobs,
        skippedGrains: 0,
        grainCapReached: false,
        sharpness: sharpness,
      ),
    );
  }

  // -- STAGE E+F: per-grain SAM decode -> crop -----------------------------
  final decoderSession =
      OrtSession.fromBuffer(req.decoderModelBytes, OrtSessionOptions());

  final results = <_GrainCropData>[];
  var skippedGrains = 0;
  final stageEF = Stopwatch()..start();

  for (int bi = 0; bi < blobs.length; bi++) {
    final blob = blobs[bi];
    final crop = await _decodeGrainWithSAM(
      decoderSession: decoderSession,
      embedFlat: embedFlat,
      embedShape: embedShape,
      workImg: workImg,
      cropImg: cropImg,
      blob: blob,
      workW: workW,
      workH: workH,
      cropW: cropW,
      blobIndex: bi,
    );
    if (crop != null) {
      results.add(crop);
    } else {
      skippedGrains++;
    }
  }

  stageEF.stop();
  debugPrint('[GrainSegmenter] E+F decode+crop: ${stageEF.elapsedMilliseconds}ms  '
      'kept=${results.length}/${blobs.length}');

  // -- STAGE G: release sessions -------------------------------------------
  decoderSession.release();

  return _SegmentationResult(
    results,
    SegmentationReport(
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      rawComponents: rawComponents,
      usableGrains: usableGrains,
      touchingBlobs: touchingBlobs,
      skippedGrains: skippedGrains,
      grainCapReached: grainCapReached,
      sharpness: sharpness,
    ),
  );
}

// ---------------------------------------------------------------------------
// Helper: resize long side with area (box) interpolation
// ---------------------------------------------------------------------------

img.Image _resizeLongSide(img.Image src, int longSide) {
  final longSrc = math.max(src.width, src.height);
  if (longSrc <= longSide) return src;
  final scale = longSide / longSrc;
  final newW = (src.width * scale).round();
  final newH = (src.height * scale).round();
  return img.copyResize(src,
      width: newW, height: newH, interpolation: img.Interpolation.average);
}

double _calculateTileSharpness(img.Image work) {
  final gray = Uint8List(work.width * work.height);
  for (var y = 0; y < work.height; y++) {
    for (var x = 0; x < work.width; x++) {
      final px = work.getPixel(x, y);
      gray[y * work.width + x] = (0.299 * img.getRed(px) +
              0.587 * img.getGreen(px) +
              0.114 * img.getBlue(px))
          .round()
          .clamp(0, 255);
    }
  }
  var maximum = 0.0;
  for (var ty = 0; ty < 6; ty++) {
    for (var tx = 0; tx < 6; tx++) {
      final x0 = (work.width * tx ~/ 6).clamp(1, work.width - 2);
      final x1 = (work.width * (tx + 1) ~/ 6).clamp(x0 + 1, work.width - 1);
      final y0 = (work.height * ty ~/ 6).clamp(1, work.height - 2);
      final y1 = (work.height * (ty + 1) ~/ 6).clamp(y0 + 1, work.height - 1);
      final values = <double>[];
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = y * work.width + x;
          values.add((4 * gray[i] - gray[i - work.width] -
                  gray[i + work.width] - gray[i - 1] - gray[i + 1])
              .toDouble());
        }
      }
      if (values.isEmpty) continue;
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              values.length;
      if (variance > maximum) maximum = variance;
    }
  }
  return maximum;
}

// ---------------------------------------------------------------------------
// Helper: build SAM encoder input tensor (NCHW float32, 1x3x1024x1024)
// ---------------------------------------------------------------------------

Float32List _buildEncoderTensor(img.Image src, int w, int h) {
  const s = AppConstants.samSide;
  // SAM ImageNet normalisation constants
  const meanR = 123.675, meanG = 116.28, meanB = 103.53;
  const stdR = 58.395, stdG = 57.12, stdB = 57.375;

  final tensor = Float32List(1 * 3 * s * s); // zero-initialised (padding)
  const planeR = 0 * s * s;
  const planeG = 1 * s * s;
  const planeB = 2 * s * s;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final px = src.getPixel(x, y);
      final idx = y * s + x;
      tensor[planeR + idx] = (img.getRed(px) - meanR) / stdR;
      tensor[planeG + idx] = (img.getGreen(px) - meanG) / stdG;
      tensor[planeB + idx] = (img.getBlue(px) - meanB) / stdB;
    }
  }
  return tensor;
}

// ---------------------------------------------------------------------------
// Helper: flatten nested ORT output value to Float32List
// ---------------------------------------------------------------------------

Float32List _flattenToFloat32(dynamic value) {
  if (value is Float32List) return value;
  if (value is List<double>) return Float32List.fromList(value);
  final buf = <double>[];
  void recurse(dynamic v) {
    if (v is double) {
      buf.add(v);
    } else if (v is List) {
      for (final item in v) recurse(item);
    }
  }
  recurse(value);
  return Float32List.fromList(buf);
}

/// Infer shape from nested list.
List<int> _inferEmbedShape(dynamic value) {
  final dims = <int>[];
  dynamic cur = value;
  while (cur is List) {
    dims.add(cur.length);
    cur = cur.isNotEmpty ? cur[0] : null;
  }
  return dims;
}

// ---------------------------------------------------------------------------
// Blob descriptor
// ---------------------------------------------------------------------------

class _Blob {
  final int x0, y0, x1, y1;
  final int area;
  const _Blob(this.x0, this.y0, this.x1, this.y1, this.area);
}

// ---------------------------------------------------------------------------
// Grain finder (on WORK copy)
// ---------------------------------------------------------------------------

List<_Blob> _findGrainBlobs(img.Image work, int w, int h) {
  // -- Gray + saturation channels --
  final gray = Uint8List(w * h);
  final sat = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final px = work.getPixel(x, y);
      final r = img.getRed(px).toDouble();
      final g = img.getGreen(px).toDouble();
      final b = img.getBlue(px).toDouble();
      gray[y * w + x] =
          (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
      final mx = math.max(r, math.max(g, b));
      final mn = math.min(r, math.min(g, b));
      sat[y * w + x] =
          (mx == 0 ? 0 : ((mx - mn) / mx * 255)).round().clamp(0, 255);
    }
  }

  // -- Background estimate: scale to 1/8, blur, scale back --
  // This replaces the Python 101x101 median blur cheaply.
  final bW = math.max(1, w ~/ 8);
  final bH = math.max(1, h ~/ 8);
  final smallGray = _scaleChannel(gray, w, h, bW, bH);
  final smallSat = _scaleChannel(sat, w, h, bW, bH);
  // 20 passes of a 3x3 box ~ a 13-cell window at 1/8 scale ~ the 101 px window
  // of the validated Python median blur, so grains do not leak into the background.
  final blurGray = _boxBlur(smallGray, bW, bH, 20);
  final blurSat = _boxBlur(smallSat, bW, bH, 20);
  final bgGray = _scaleChannel(blurGray, bW, bH, w, h);
  final bgSat = _scaleChannel(blurSat, bW, bH, w, h);

  // -- Binary mask --
  final mask = Uint8List(w * h);
  final dt = AppConstants.diffThreshold;
  final st = AppConstants.satThreshold;
  for (int i = 0; i < w * h; i++) {
    final dg = (gray[i] - bgGray[i]).abs();
    final ds = (sat[i] - bgSat[i]).abs();
    mask[i] = (dg > dt || ds > st) ? 1 : 0;
  }

  // -- Morphological open 3x3, close 5x5 --
  final opened = _morphOpen(mask, w, h, 3);
  final closed = _morphClose(opened, w, h, 5);

  // -- Connected components (8-connectivity, union-find) --
  final labels = Int32List(w * h);
  final parent = <int>[];
  int nextLabel = 0;

  int find(int a) {
    while (parent[a] != a) {
      parent[a] = parent[parent[a]];
      a = parent[a];
    }
    return a;
  }

  void unite(int a, int b) {
    a = find(a);
    b = find(b);
    if (a != b) parent[b] = a;
  }

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = y * w + x;
      if (closed[i] == 0) {
        labels[i] = -1;
        continue;
      }
      final up = (y > 0) ? labels[(y - 1) * w + x] : -1;
      final left = (x > 0) ? labels[y * w + x - 1] : -1;
      final uleft = (y > 0 && x > 0) ? labels[(y - 1) * w + x - 1] : -1;
      final uright =
          (y > 0 && x < w - 1) ? labels[(y - 1) * w + x + 1] : -1;
      final neighbours =
          [up, left, uleft, uright].where((v) => v >= 0).toList();
      if (neighbours.isEmpty) {
        parent.add(nextLabel);
        labels[i] = nextLabel++;
      } else {
        final minLabel = neighbours.reduce(math.min);
        labels[i] = minLabel;
        for (final nb in neighbours) {
          if (nb != minLabel) unite(minLabel, nb);
        }
      }
    }
  }

  for (int i = 0; i < w * h; i++) {
    if (labels[i] >= 0) labels[i] = find(labels[i]);
  }

  // Compute bounding boxes and areas
  final bx0 = <int, int>{}, by0 = <int, int>{},
      bx1 = <int, int>{}, by1 = <int, int>{}, areas = <int, int>{};
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final lbl = labels[y * w + x];
      if (lbl < 0) continue;
      final a = areas[lbl] ?? 0;
      areas[lbl] = a + 1;
      if (a == 0) {
        bx0[lbl] = x; by0[lbl] = y; bx1[lbl] = x; by1[lbl] = y;
      } else {
        if (x < bx0[lbl]!) bx0[lbl] = x;
        if (y < by0[lbl]!) by0[lbl] = y;
        if (x > bx1[lbl]!) bx1[lbl] = x;
        if (y > by1[lbl]!) by1[lbl] = y;
      }
    }
  }

  final rawCount = areas.length;
  int aboveMax = 0;
  final blobs = <_Blob>[];
  for (final entry in areas.entries) {
    final area = entry.value;
    if (area > AppConstants.maxArea) { aboveMax++; continue; }
    if (area < AppConstants.minArea) continue;
    final lbl = entry.key;
    blobs.add(_Blob(bx0[lbl]!, by0[lbl]!, bx1[lbl]!, by1[lbl]!, area));
  }
  final usable = blobs.length;
  blobs.sort((a, b) => b.area.compareTo(a.area));
  if (blobs.length > AppConstants.maxGrains) blobs.length = AppConstants.maxGrains;

  debugPrint('[GrainSegmenter] D components: raw=$rawCount  '
      'usable=$usable  aboveMax=$aboveMax  kept=${blobs.length}');
  _lastRawComponents = rawCount;
  _lastTouchingBlobs = aboveMax;
  return blobs;
}

// ---------------------------------------------------------------------------
// Per-grain SAM decode
// ---------------------------------------------------------------------------

Future<_GrainCropData?> _decodeGrainWithSAM({
  required OrtSession decoderSession,
  required Float32List embedFlat,
  required List<int> embedShape,
  required img.Image workImg,
  required img.Image cropImg,
  required _Blob blob,
  required int workW,
  required int workH,
  required int cropW,
  required int blobIndex,
}) async {
  final pad = AppConstants.boxPad;
  final bx0 = math.max(0, blob.x0 - pad);
  final by0 = math.max(0, blob.y0 - pad);
  final bx1 = math.min(workW - 1, blob.x1 + pad);
  final by1 = math.min(workH - 1, blob.y1 + pad);
  final cx = (bx0 + bx1) / 2.0;
  final cy = (by0 + by1) / 2.0;

  // Centre-point prompt
  List<bool>? mask = await _runDecoder(
    session: decoderSession,
    embedFlat: embedFlat,
    embedShape: embedShape,
    workW: workW,
    workH: workH,
    pointCoords: [[cx, cy], [0.0, 0.0]],
    pointLabels: [1.0, -1.0],
    blobArea: blob.area,
    blobBx0: bx0, blobBy0: by0, blobBx1: bx1, blobBy1: by1,
  );

  // Sanity failed: retry with box prompt
  if (mask == null) {
    debugPrint('[GrainSegmenter] grain#$blobIndex: centre prompt failed sanity, '
        'retrying with box prompt');
    mask = await _runDecoder(
      session: decoderSession,
      embedFlat: embedFlat,
      embedShape: embedShape,
      workW: workW,
      workH: workH,
      pointCoords: [
        [bx0.toDouble(), by0.toDouble()],
        [bx1.toDouble(), by1.toDouble()],
      ],
      pointLabels: [2.0, 3.0],
      blobArea: blob.area,
      blobBx0: bx0, blobBy0: by0, blobBx1: bx1, blobBy1: by1,
    );
    if (mask == null) {
      debugPrint(
          '[GrainSegmenter] grain#$blobIndex: box prompt also failed -- skipping');
      return null;
    }
  }

  // Mask bounding box in WORK coordinates
  int mx0 = workW, my0 = workH, mx1 = 0, my1 = 0;
  for (int y = 0; y < workH; y++) {
    for (int x = 0; x < workW; x++) {
      if (mask[y * workW + x]) {
        if (x < mx0) mx0 = x;
        if (y < my0) my0 = y;
        if (x > mx1) mx1 = x;
        if (y > my1) my1 = y;
      }
    }
  }
  if (mx0 > mx1 || my0 > my1) return null;

  // Map to CROP SOURCE coordinates
  final ratio = cropW / workW;
  final cmx0 = (mx0 * ratio).floor();
  final cmy0 = (my0 * ratio).floor();
  final cmx1 = (mx1 * ratio).ceil();
  final cmy1 = (my1 * ratio).ceil();

  // Upsample mask to crop-source region (nearest-neighbour from work mask)
  final cropRW = cmx1 - cmx0 + 1;
  final cropRH = cmy1 - cmy0 + 1;
  final cropMask = List<bool>.filled(cropRW * cropRH, false);
  for (int cy2 = 0; cy2 < cropRH; cy2++) {
    for (int cx2 = 0; cx2 < cropRW; cx2++) {
      final wx = ((cmx0 + cx2) / ratio).round().clamp(0, workW - 1);
      final wy = ((cmy0 + cy2) / ratio).round().clamp(0, workH - 1);
      cropMask[cy2 * cropRW + cx2] = mask[wy * workW + wx];
    }
  }

  // Mask bbox in local crop coords
  int lmx0 = cropRW, lmy0 = cropRH, lmx1 = 0, lmy1 = 0;
  for (int y = 0; y < cropRH; y++) {
    for (int x = 0; x < cropRW; x++) {
      if (cropMask[y * cropRW + x]) {
        if (x < lmx0) lmx0 = x;
        if (y < lmy0) lmy0 = y;
        if (x > lmx1) lmx1 = x;
        if (y > lmy1) lmy1 = y;
      }
    }
  }

  final cpPad = AppConstants.cropPadPx;
  final cropH = cropImg.height;
  final finalX0 = math.max(0, cmx0 + lmx0 - cpPad);
  final finalY0 = math.max(0, cmy0 + lmy0 - cpPad);
  final finalX1 = math.min(cropImg.width - 1, cmx0 + lmx1 + cpPad);
  final finalY1 = math.min(cropH - 1, cmy0 + lmy1 + cpPad);
  final finalW = finalX1 - finalX0 + 1;
  final finalH = finalY1 - finalY0 + 1;
  if (finalW <= 0 || finalH <= 0) return null;

  // Cut rect from CROP SOURCE; fill non-mask pixels with white
  final outImg = img.Image(finalW, finalH);
  for (int y = 0; y < finalH; y++) {
    for (int x = 0; x < finalW; x++) {
      final sx = finalX0 + x;
      final sy = finalY0 + y;
      final lx = sx - cmx0;
      final ly = sy - cmy0;
      final inMask = (lx >= 0 && ly >= 0 && lx < cropRW && ly < cropRH)
          ? cropMask[ly * cropRW + lx]
          : false;
      if (inMask) {
        outImg.setPixel(x, y, cropImg.getPixel(sx, sy));
      } else {
        outImg.setPixel(x, y, 0xFFFFFFFF); // opaque white (ABGR int)
      }
    }
  }

  final pngBytes = Uint8List.fromList(img.encodePng(outImg));
  return _GrainCropData(pngBytes, finalX0, finalY0, finalW, finalH);
}

// ---------------------------------------------------------------------------
// SAM decoder call; returns boolean mask or null if sanity check fails
// ---------------------------------------------------------------------------

Future<List<bool>?> _runDecoder({
  required OrtSession session,
  required Float32List embedFlat,
  required List<int> embedShape,
  required int workW,
  required int workH,
  required List<List<double>> pointCoords,
  required List<double> pointLabels,
  required int blobArea,
  required int blobBx0,
  required int blobBy0,
  required int blobBx1,
  required int blobBy1,
}) async {
  final embedOrt =
      OrtValueTensor.createTensorWithDataList(embedFlat, embedShape);

  final coords = Float32List(4);
  coords[0] = pointCoords[0][0];
  coords[1] = pointCoords[0][1];
  coords[2] = pointCoords[1][0];
  coords[3] = pointCoords[1][1];
  final coordsOrt =
      OrtValueTensor.createTensorWithDataList(coords, [1, 2, 2]);

  final labelsArr = Float32List.fromList(pointLabels);
  final labelsOrt =
      OrtValueTensor.createTensorWithDataList(labelsArr, [1, 2]);

  final maskInput = Float32List(1 * 1 * 256 * 256);
  final maskInputOrt =
      OrtValueTensor.createTensorWithDataList(maskInput, [1, 1, 256, 256]);

  final hasMask = Float32List.fromList([0.0]);
  final hasMaskOrt =
      OrtValueTensor.createTensorWithDataList(hasMask, [1]);

  final origSize =
      Float32List.fromList([workH.toDouble(), workW.toDouble()]);
  final origSizeOrt =
      OrtValueTensor.createTensorWithDataList(origSize, [2]);

  final runOpts = OrtRunOptions();
  List<OrtValue?>? outputs;
  try {
    outputs = await session.runAsync(runOpts, {
      'image_embeddings': embedOrt,
      'point_coords': coordsOrt,
      'point_labels': labelsOrt,
      'mask_input': maskInputOrt,
      'has_mask_input': hasMaskOrt,
      'orig_im_size': origSizeOrt,
    });
  } catch (e) {
    debugPrint('[GrainSegmenter] decoder error: $e');
    return null;
  } finally {
    embedOrt.release();
    coordsOrt.release();
    labelsOrt.release();
    maskInputOrt.release();
    hasMaskOrt.release();
    origSizeOrt.release();
    runOpts.release();
  }

  final logitsRaw = _flattenToFloat32(outputs![0]!.value);
  for (final o in outputs) o?.release();

  final maskBool = List<bool>.generate(
      workH * workW, (i) => i < logitsRaw.length && logitsRaw[i] > 0);

  // Sanity: area ratio + overlap
  final maskArea = maskBool.where((v) => v).length;
  bool overlaps = false;
  outer:
  for (int y = blobBy0; y <= blobBy1; y++) {
    for (int x = blobBx0; x <= blobBx1; x++) {
      if (maskBool[y * workW + x]) { overlaps = true; break outer; }
    }
  }
  if (maskArea < blobArea * 0.5 || maskArea > blobArea * 2.5 || !overlaps) {
    return null;
  }
  return maskBool;
}

// ---------------------------------------------------------------------------
// Morphology helpers
// ---------------------------------------------------------------------------

Uint8List _morphErode(Uint8List src, int w, int h, int kSize) {
  final r = kSize ~/ 2;
  final dst = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool allOne = true;
      outer:
      for (int ky = -r; ky <= r; ky++) {
        for (int kx = -r; kx <= r; kx++) {
          final ny = y + ky, nx = x + kx;
          if (ny < 0 || ny >= h || nx < 0 || nx >= w || src[ny * w + nx] == 0) {
            allOne = false;
            break outer;
          }
        }
      }
      dst[y * w + x] = allOne ? 1 : 0;
    }
  }
  return dst;
}

Uint8List _morphDilate(Uint8List src, int w, int h, int kSize) {
  final r = kSize ~/ 2;
  final dst = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool anyOne = false;
      outer:
      for (int ky = -r; ky <= r; ky++) {
        for (int kx = -r; kx <= r; kx++) {
          final ny = y + ky, nx = x + kx;
          if (ny >= 0 && ny < h && nx >= 0 && nx < w && src[ny * w + nx] == 1) {
            anyOne = true;
            break outer;
          }
        }
      }
      dst[y * w + x] = anyOne ? 1 : 0;
    }
  }
  return dst;
}

Uint8List _morphOpen(Uint8List src, int w, int h, int kSize) =>
    _morphDilate(_morphErode(src, w, h, kSize), w, h, kSize);

Uint8List _morphClose(Uint8List src, int w, int h, int kSize) =>
    _morphErode(_morphDilate(src, w, h, kSize), w, h, kSize);

// ---------------------------------------------------------------------------
// Channel scale (nearest-neighbour) and box blur
// ---------------------------------------------------------------------------

Uint8List _scaleChannel(Uint8List src, int sw, int sh, int dw, int dh) {
  final dst = Uint8List(dw * dh);
  for (int y = 0; y < dh; y++) {
    for (int x = 0; x < dw; x++) {
      final sx = (x * sw / dw).round().clamp(0, sw - 1);
      final sy = (y * sh / dh).round().clamp(0, sh - 1);
      dst[y * dw + x] = src[sy * sw + sx];
    }
  }
  return dst;
}

Uint8List _boxBlur(Uint8List src, int w, int h, int passes) {
  Uint8List cur = src;
  for (int p = 0; p < passes; p++) {
    final dst = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int sum = 0, count = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final ny = y + ky, nx = x + kx;
            if (ny >= 0 && ny < h && nx >= 0 && nx < w) {
              sum += cur[ny * w + nx];
              count++;
            }
          }
        }
        dst[y * w + x] = (sum / count).round();
      }
    }
    cur = dst;
  }
  return cur;
}
