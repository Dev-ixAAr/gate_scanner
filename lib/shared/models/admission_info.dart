// ============================================================================
// Admission Info — Multi-admission ticket fields from validate/check-in API
//
// Parsed from: admissions_used, admissions_max, admissions_remaining,
// validation_message (same shape on validate and check-in responses).
// ============================================================================

/// Admission counters and server message from ticket validation responses.
class AdmissionInfo {
  const AdmissionInfo({
    this.admissionsUsed = 0,
    this.admissionsMax = 1,
    this.admissionsRemaining = 0,
    this.validationMessage = '',
  });

  final int admissionsUsed;
  final int admissionsMax;
  final int admissionsRemaining;
  final String validationMessage;

  /// True when the package allows more than one gate scan per QR.
  bool get isMultiAdmission => admissionsMax > 1;

  /// Admissions consumed, preferring [admissionsUsed] but falling back to
  /// `admissions_max - admissions_remaining` when the API reports `used: 0`
  /// after a successful scan.
  int get effectiveAdmissionsUsed {
    if (admissionsUsed > 0) return admissionsUsed;
    if (admissionsMax > 0 && admissionsRemaining < admissionsMax) {
      return admissionsMax - admissionsRemaining;
    }
    return admissionsUsed;
  }

  /// Subtitle for valid multi-admission scans: "Admission 2 of 6".
  String? get admissionProgressLabel {
    if (!isMultiAdmission || effectiveAdmissionsUsed <= 0) return null;
    return 'Admission $effectiveAdmissionsUsed of $admissionsMax';
  }

  /// Compact counter for info rows: "2/6".
  String? get admissionCounterLabel {
    if (!isMultiAdmission || effectiveAdmissionsUsed <= 0) return null;
    return '$effectiveAdmissionsUsed/$admissionsMax';
  }

  /// True when all admissions on this ticket have been consumed.
  bool get isFullyExhausted =>
      admissionsMax > 0 && admissionsRemaining <= 0;

  factory AdmissionInfo.fromJson(Map<String, dynamic> json) {
    final int admissionsMax = _resolveAdmissionsMax(json);
    final int admissionsUsed = _int(json, 'admissions_used');
    final int? remainingFromApi = _optionalInt(json, 'admissions_remaining');
    final int admissionsRemaining = remainingFromApi ??
        (admissionsMax - admissionsUsed).clamp(0, admissionsMax);

    return AdmissionInfo(
      admissionsUsed: admissionsUsed,
      admissionsMax: admissionsMax,
      admissionsRemaining: admissionsRemaining,
      validationMessage: _str(json, 'validation_message'),
    );
  }

  static int _resolveAdmissionsMax(Map<String, dynamic> json) {
    final int fromMax = _optionalInt(json, 'admissions_max') ?? -1;
    if (fromMax > 0) return fromMax;
    final int fromAdmitCount = _optionalInt(json, 'admit_count') ?? -1;
    if (fromAdmitCount > 0) return fromAdmitCount;
    return 1;
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _str(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _int(
    Map<String, dynamic> json,
    String key, {
    int fallback = 0,
  }) {
    final dynamic value = json[key];
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
