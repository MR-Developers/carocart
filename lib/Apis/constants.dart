class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    "BASE_URL",
    defaultValue: "http://10.0.2.2",
  );
  static const String prodUrl = String.fromEnvironment(
    "PROD_URL",
    defaultValue: "https://api.carocart.com",
  );
}
