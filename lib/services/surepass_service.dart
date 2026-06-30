import '../core/error/exceptions.dart';
import '../core/network/dio_client.dart';
import '../models/verification_results.dart';

/// Data-layer client for the SurePass KYC/verification APIs.
///
/// Each method maps a SurePass JSON response into a strongly-typed model.
/// Network/transport errors surface as [ServerException]/[NetworkException]
/// from [DioClient]; business-level failures throw [VerificationException].
///
/// NOTE: SurePass response shapes are wrapped as
/// `{ "data": {...}, "status_code": 200, "success": true, "message": "..." }`.
class SurepassService {
  SurepassService(this._client);

  final DioClient _client;

  /// Verifies a PAN and (optionally) cross-checks the holder name.
  Future<PanVerificationResult> verifyPan({
    required String panNumber,
    String? expectedName,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/pan/pan',
      data: {'id_number': panNumber},
    );

    final data = _unwrap(response.data, 'PAN verification failed.');
    final nameOnPan = (data['full_name'] ?? data['name'] ?? '') as String;
    final isValid = (data['pan_number'] ?? data['id_number']) != null;

    bool? nameMatch;
    if (expectedName != null && expectedName.isNotEmpty && nameOnPan.isNotEmpty) {
      nameMatch = _fuzzyNameMatch(expectedName, nameOnPan);
    }

    return PanVerificationResult(
      panNumber: (data['pan_number'] ?? panNumber) as String,
      nameOnPan: nameOnPan,
      isValid: isValid,
      category: data['category'] as String?,
      nameMatch: nameMatch,
    );
  }

  /// Compares two face images (base64) and returns a confidence percentage.
  ///
  /// [referenceImage] is typically the Aadhaar QR photo; [selfieImage] is the
  /// freshly captured live selfie. Neither image is persisted by Trvsty.
  Future<FaceMatchResult> faceMatch({
    required String referenceImageBase64,
    required String selfieImageBase64,
    double threshold = 70.0,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/face/face-match',
      data: {
        'image_1': referenceImageBase64,
        'image_2': selfieImageBase64,
      },
    );

    final data = _unwrap(response.data, 'Face match failed.');
    // SurePass returns match score as a fraction (0–1) or percentage.
    final raw = (data['match_score'] ?? data['confidence'] ?? 0) as num;
    final confidence = raw <= 1 ? raw * 100 : raw.toDouble();

    return FaceMatchResult(
      confidence: confidence.toDouble(),
      isMatch: confidence >= threshold,
    );
  }

  /// Screens for adverse criminal / court records by name + dob.
  Future<CriminalRecordResult> criminalRecordCheck({
    required String name,
    required String dateOfBirth,
    String? fatherName,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/criminal-court/search',
      data: {
        'name': name,
        'date_of_birth': dateOfBirth,
        if (fatherName != null) 'father_name': fatherName,
      },
    );

    final data = _unwrap(response.data, 'Criminal record check failed.');
    final records = (data['records'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? e['case_details'] ?? e['title'] : e).toString())
        .toList();

    return CriminalRecordResult(
      hasRecords: records.isNotEmpty,
      recordCount: records.length,
      records: records,
    );
  }

  /// Initialises a DigiLocker authorization session and returns the URL the
  /// user must visit to grant consent. Documents are fetched server-side after
  /// consent via the returned session id.
  Future<DigiLockerSession> initDigiLocker({required String redirectUrl}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/digilocker/initialize',
      data: {'redirect_url': redirectUrl, 'signup_flow': false},
    );

    final data = _unwrap(response.data, 'Could not start DigiLocker session.');
    return DigiLockerSession(
      sessionId: (data['client_id'] ?? data['session_id'] ?? '') as String,
      authorizationUrl: (data['url'] ?? data['authorization_url'] ?? '') as String,
    );
  }

  // --- helpers ---------------------------------------------------------------

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body, String onError) {
    if (body == null) throw VerificationException(onError);
    final success = body['success'] as bool? ?? false;
    if (!success) {
      throw VerificationException(
        (body['message'] as String?) ?? onError,
        code: body['status_code']?.toString(),
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw VerificationException(onError);
    }
    return data;
  }

  /// Case-insensitive token-overlap name match (handles ordering/initials).
  bool _fuzzyNameMatch(String a, String b) {
    Set<String> tokens(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    final ta = tokens(a);
    final tb = tokens(b);
    if (ta.isEmpty || tb.isEmpty) return false;
    final overlap = ta.intersection(tb).length;
    return overlap / ta.length >= 0.6;
  }
}

/// DigiLocker authorization handshake result.
class DigiLockerSession {
  const DigiLockerSession({required this.sessionId, required this.authorizationUrl});
  final String sessionId;
  final String authorizationUrl;
}
