class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.222.158.243:8000',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Photomi',
  );
}
