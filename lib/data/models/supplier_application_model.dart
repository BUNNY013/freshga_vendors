class SupplierApplicationModel {
  final String applicationId;
  final String userId;

  final String fullName;
  final String businessName;

  final String phone;
  final String email;

  final String instagramLink;

  final String businessDescription;
  final List<String> foodCategories;
  final String dispatchTime;
  final String experience;

  final String businessAddress;
  final String pickupAddress;
  final String city;
  final String state;
  final String pincode;

  final String fssaiNumber;
  final String fssaiCertificateImage;

  final String panNumber;
  final String panImage;

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
    required this.email,
    required this.instagramLink,
    required this.businessDescription,
    required this.foodCategories,
    required this.dispatchTime,
    required this.experience,
    required this.businessAddress,
    required this.pickupAddress,
    required this.city,
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
      email: json['email'] ?? '',
      instagramLink: json['instagramLink'] ?? '',
      businessDescription: json['businessDescription'] ?? '',
      foodCategories: List<String>.from(json['foodCategories'] ?? []),
      dispatchTime: json['dispatchTime'] ?? '',
      experience: json['experience'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      fssaiNumber: json['fssaiNumber'] ?? '',
      fssaiCertificateImage: json['fssaiCertificateImage'] ?? '',
      panNumber: json['panNumber'] ?? '',
      panImage: json['panImage'] ?? '',
      bankDetails: Map<String, dynamic>.from(json['bankDetails'] ?? {}),
      status: json['status'] ?? 'pending',
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
      'email': email,
      'instagramLink': instagramLink,
      'businessDescription': businessDescription,
      'foodCategories': foodCategories,
      'dispatchTime': dispatchTime,
      'experience': experience,
      'businessAddress': businessAddress,
      'pickupAddress': pickupAddress,
      'city': city,
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
