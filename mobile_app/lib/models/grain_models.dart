class GrainBox {
  final int x, y, w, h;
  final double score;

  GrainBox({
    required this.x, required this.y,
    required this.w, required this.h,
    required this.score,
  });

  factory GrainBox.fromJson(Map<String, dynamic> json) => GrainBox(
    x: json['x'], y: json['y'],
    w: json['w'], h: json['h'],
    score: (json['score'] ?? 0.0).toDouble(),
  );
}

class GrainResult {
  final String className;
  final double confidence;
  final List<double> probabilities;

  GrainResult({
    required this.className,
    required this.confidence,
    required this.probabilities,
  });
}

class BatchResult {
  final List<GrainResult> grains;
  final Map<String, int> counts;
  final String dominant;
  final String recommendation;
  final DateTime timestamp;
  final String imagePath;

  BatchResult({
    required this.grains,
    required this.counts,
    required this.dominant,
    required this.recommendation,
    required this.timestamp,
    required this.imagePath,
  });

  int get total => grains.length;

  double percentOf(String cls) =>
      total == 0 ? 0 : (counts[cls] ?? 0) / total * 100;
}