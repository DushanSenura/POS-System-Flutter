class EmployeeChangeRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? requestedName;
  final String? requestedEmail;
  final String? requestedPhone;
  final String? currentName;
  final String? currentEmail;
  final String? currentPhone;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  EmployeeChangeRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.requestedName,
    this.requestedEmail,
    this.requestedPhone,
    this.currentName,
    this.currentEmail,
    this.currentPhone,
    required this.requestedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  EmployeeChangeRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? requestedName,
    String? requestedEmail,
    String? requestedPhone,
    String? currentName,
    String? currentEmail,
    String? currentPhone,
    DateTime? requestedAt,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return EmployeeChangeRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      requestedName: requestedName ?? this.requestedName,
      requestedEmail: requestedEmail ?? this.requestedEmail,
      requestedPhone: requestedPhone ?? this.requestedPhone,
      currentName: currentName ?? this.currentName,
      currentEmail: currentEmail ?? this.currentEmail,
      currentPhone: currentPhone ?? this.currentPhone,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get hasNameChange =>
      requestedName != null && requestedName != currentName;
  bool get hasEmailChange =>
      requestedEmail != null && requestedEmail != currentEmail;
  bool get hasPhoneChange =>
      requestedPhone != null && requestedPhone != currentPhone;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'requestedName': requestedName,
      'requestedEmail': requestedEmail,
      'requestedPhone': requestedPhone,
      'currentName': currentName,
      'currentEmail': currentEmail,
      'currentPhone': currentPhone,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory EmployeeChangeRequest.fromJson(Map<String, dynamic> json) {
    return EmployeeChangeRequest(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      requestedName: json['requestedName'] as String?,
      requestedEmail: json['requestedEmail'] as String?,
      requestedPhone: json['requestedPhone'] as String?,
      currentName: json['currentName'] as String?,
      currentEmail: json['currentEmail'] as String?,
      currentPhone: json['currentPhone'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: json['status'] as String,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
