class AppConstants {
  static const String appName = 'MUSTAV';
  static const String tagline = 'Crafted for your cravings';

  /// Simulated network fetch used in place of a real backend (spec allows
  /// simulating with timed local state). Set to true in the demo build to
  /// randomly fail order submission so the retry flow (3.4) can be verified.
  static const bool simulateRandomOrderFailure = true;
}
