class AppConstants {
  // App Info
  static const String appName = 'Rice Mold Detector';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = 'https://your-api-endpoint.com/api';
  static const String segmentationEndpoint = '/segment';

  //  SAM API 
  // Replace with your ngrok URL each time you start Colab
  static const String samApiUrl = 'https://diversiform-revivable-killian.ngrok-free.dev';
  static const String samSegmentEndpoint = '/segment';

  //  Gemini API 
  // Pass via --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  //  TFLite Model
  static const String modelPath = 'assets/models/efficientnet_rice_FINAL.tflite';
  static const String labelsPath = 'assets/models/labels.json';
  static const int modelInputSize = 224;

  //  Two-Stage Pipeline Models
  static const String stage1ModelPath = 'assets/models/stage1_healthy_vs_mold.tflite';
  static const String stage2ModelPath = 'assets/models/stage2_earlyrisk_vs_spoiled.tflite';
  static const int stageInputSize = 224;
  
  //  Class Labels
  static const String classHealthy = 'healthy';
  static const String classEarlyRisk = 'early_risk';
  static const String classSpoiled = 'spoiled';
  
  static const List<String> classNames = [
    classHealthy,
    classEarlyRisk, 
    classSpoiled
  ];

  // EfficientNet Preprocessing
  static const List<double> mean = [0.485, 0.456, 0.406];
  static const List<double> std  = [0.229, 0.224, 0.225];

  //  Batch Assessment Thresholds 
  static const double spoiledAlertThreshold    = 0.20; // >20% spoiled = alert
  static const double earlyRiskAlertThreshold  = 0.20; // >20% early risk

  /*// Model Constants
  static const String modelFileName = 'efficientnet_rice_FINAL.tflite';
  static const int modelInputSize = 224;
  static const int numClasses = 3;
  
  // Classification Thresholds
  static const double confidenceThreshold = 0.6;
  static const double earlyRiskThreshold = 0.25;
  static const double spoiledThreshold = 0.25;
  
  // Batch Assessment Rules
  static const double healthyBatchThreshold = 0.80; // 80% healthy
  static const double earlyRiskBatchThreshold = 0.30; // >30% early-risk/spoiled*/
  
  // Camera Settings
  static const double optimalCameraDistance = 27.5; // 25-30cm average
  static const int minGrainCount = 30;
  static const int maxGrainCount = 150;
  static const int targetGrainCount = 87;
  
  // Image Quality Checks
  static const double blurThreshold = 100.0; // Laplacian variance
  static const double minBrightness = 80.0;
  static const double maxBrightness = 200.0;
  
  // Database
  static const String dbName    = 'rice_mold.db';
  static const int    dbVersion = 1;
  
  // SharedPreferences Keys
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyPinCode = 'pin_code';
  static const String keyUseBiometric = 'use_biometric';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // Timeout Durations
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cameraInitTimeout = Duration(seconds: 10);
}