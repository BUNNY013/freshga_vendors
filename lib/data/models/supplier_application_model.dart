class SupplierApplicationModel {
  final String applicationId;
  final String userId;

  final String fullName;
  final String businessName;

  final String phone;
  final String alternatePhone;
  final String email;

  // Tax & Legal Compliance
  final String taxRegistrationType; // 'GSTIN', 'EnrolmentNumber', 'NeedsHelp'
  final String taxNumber;
  final String taxImage;

  final String fssaiStatus; // 'Have', 'NeedsHelp'
  final String fssaiNumber;
  final String fssaiCertificateImage;

  final String panNumber;
  final String panImage;

  // Address
  final String businessAddress;
  final String village;
  final String city;
  final String district;
  final String state;
  final String pincode;



  final Map<String, dynamic> bankDetails;

  final String status;

  final String adminRemarks;

  final String submittedAt;
  final String verifiedAt;

  SupplierApplicationModel({
    required this.applicationId,
    required this.userId,
    required this.fullName,
    required this.businessName,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.taxRegistrationType,
    required this.taxNumber,
    required this.taxImage,
    required this.fssaiStatus,
    required this.businessAddress,
    required this.village,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.fssaiNumber,
    required this.fssaiCertificateImage,
    required this.panNumber,
    required this.panImage,
    required this.bankDetails,
    required this.status,
    required this.adminRemarks,
    required this.submittedAt,
    required this.verifiedAt,
  });

  factory SupplierApplicationModel.fromJson(Map<String, dynamic> json) {
    return SupplierApplicationModel(
      applicationId: json['applicationId'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      businessName: json['businessName'] ?? '',
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'] ?? '',
      email: json['email'] ?? '',
      taxRegistrationType: json['taxRegistrationType'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      taxImage: json['taxImage'] ?? '',
      fssaiStatus: json['fssaiStatus'] ?? '',
      businessAddress: json['businessAddress'] ?? json['pickupAddress'] ?? '',
      village: json['village'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      fssaiNumber: json['fssaiNumber'] ?? '',
      fssaiCertificateImage: json['fssaiCertificateImage'] ?? '',
      panNumber: json['panNumber'] ?? '',
      panImage: json['panImage'] ?? '',
      bankDetails: Map<String, dynamic>.from(json['bankDetails'] ?? {}),
      status: json['status'] ?? 'draft',
      adminRemarks: json['adminRemarks'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
      verifiedAt: json['verifiedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'userId': userId,
      'fullName': fullName,
      'businessName': businessName,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'taxRegistrationType': taxRegistrationType,
      'taxNumber': taxNumber,
      'taxImage': taxImage,
      'fssaiStatus': fssaiStatus,
      'businessAddress': businessAddress,
      'village': village,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'fssaiNumber': fssaiNumber,
      'fssaiCertificateImage': fssaiCertificateImage,
      'panNumber': panNumber,
      'panImage': panImage,
      'bankDetails': bankDetails,
      'status': status,
      'adminRemarks': adminRemarks,
      'submittedAt': submittedAt,
      'verifiedAt': verifiedAt,
    };
  }
}
