import 'package:equatable/equatable.dart';

class Batch extends Equatable {
  final String id;
  final String batchNumber;
  final String? source;
  final String? variety;
  final double? quantity;
  final DateTime storageDate;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? latestResult;
  final DateTime? latestScanTime;
  final int scanCount;
  
  const Batch({
    required this.id,
    required this.batchNumber,
    this.source,
    this.variety,
    this.quantity,
    required this.storageDate,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.latestResult,
    this.latestScanTime,
    this.scanCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'batch_number': batchNumber,
    'variety': variety,
    'source': source,
    'quantity': quantity,
    'storage_date': storageDate.toUtc().toIso8601String(),
    'location': location,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory Batch.fromMap(Map<String, dynamic> map) => Batch(
    id: map['id'] as String,
    batchNumber: map['batch_number'] as String,
    variety: map['variety'] as String?,
    source: map['source'] as String?,
    quantity: (map['quantity'] as num?)?.toDouble(),
    storageDate: DateTime.parse(map['storage_date'] as String).toLocal(),
    location: map['location'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    latestResult: map['latest_result'] as String?,
    latestScanTime: (map['latest_scan_time'] as String?) == null
        ? null
        : DateTime.parse(map['latest_scan_time'] as String).toLocal(),
    scanCount: (map['scan_count'] as num?)?.toInt() ?? 0,
  );
  
  @override
  List<Object?> get props => [
    id,
    batchNumber,
    source,
    variety,
    quantity,
    storageDate,
    location,
    createdAt,
    updatedAt,
    latestResult,
    latestScanTime,
    scanCount,
  ];
}