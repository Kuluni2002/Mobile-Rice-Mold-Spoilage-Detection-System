import 'package:equatable/equatable.dart';

class Batch extends Equatable {
  final String id;
  final String name;
  final String? source;
  final String? variety;
  final double? quantity;
  final DateTime storageDate;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Batch({
    required this.id,
    required this.name,
    this.source,
    this.variety,
    this.quantity,
    required this.storageDate,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  List<Object?> get props => [
    id,
    name,
    source,
    variety,
    quantity,
    storageDate,
    location,
    createdAt,
    updatedAt,
  ];
}