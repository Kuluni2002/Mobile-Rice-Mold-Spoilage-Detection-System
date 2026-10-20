class ClassificationResult {
  final String label;
  final double confidence;
  final DateTime timestamp;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.timestamp,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  
  String get riskLevel {
    if (label == 'healthy') return 'Low';
    if (label == 'early_risk') return 'Medium';
    if (label == 'spoiled') return 'High';
    return 'Unknown';
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      label: json['label'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}