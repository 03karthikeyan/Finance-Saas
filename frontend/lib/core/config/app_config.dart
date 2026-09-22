class AppConfig {
  static const String appName = 'FinanceMaster Pro';
  static const String appFullName = 'FinanceMaster Pro (FMP)';
  static const String poweredBy = 'Powered by Mediawave Technologies';
  static const String appVersion = '1.0.0';

  // Default to Render Cloud URL for production cloud hosting
  static String baseApiUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mwt-finance-backend.onrender.com/api/v1',
  );

  // Common preset endpoints for fast switching
  static const String presetRenderCloud = 'https://mwt-finance-backend.onrender.com/api/v1';
  static const String presetWifiLan = 'http://192.168.1.33:5000/api/v1';
  static const String presetLocalhost = 'http://localhost:5000/api/v1';
  static const String presetEmulator = 'http://10.0.2.2:5000/api/v1';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static void setBaseApiUrl(String url) {
    baseApiUrl = url;
  }
}
