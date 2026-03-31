class ApiConfig {
  ApiConfig._();

  // Keep mock auth enabled until the real backend URL and endpoint are ready.
  static const bool useMockAuth = true;
  static const bool useMockPatients = true;
  static const String authHeaderName = 'Authorization';
  static const String authTokenPrefix = 'Bearer';
  static const int requestTimeoutSeconds = 15;
  static const String baseUrl = 'https://your-api-url.com/api';
  static const String loginEndpoint = '/auth/login';
  static const String patientsEndpoint = '/patients';
  static const String createPatientEndpoint = '/patients';
  static const String updatePatientEndpoint = '/patients/{roomNumber}';
  static const String deletePatientEndpoint = '/patients/{roomNumber}';

  static bool get hasConfiguredBaseUrl =>
      baseUrl.startsWith('http') && !baseUrl.contains('your-api-url.com');

  static bool get canUseRealPatientsApi =>
      !useMockPatients && hasConfiguredBaseUrl && patientsEndpoint.isNotEmpty;

  static bool get canPushRealPatientChanges =>
      !useMockPatients &&
      hasConfiguredBaseUrl &&
      createPatientEndpoint.isNotEmpty &&
      updatePatientEndpoint.isNotEmpty &&
      deletePatientEndpoint.isNotEmpty;
}
