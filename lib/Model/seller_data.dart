class SellerData {
  String? username;
  String? phoneNumber;
  String? email;
  String? password;

  String? icName;
  String? icNumber;
  String? icFrontImagePath; // Store file path or URL after upload
  String? bankStatementImagePath; // Store file path or URL after upload

  String? businessName;
  String? address;
  String? postcode;
  String? state;

  SellerData({
    this.username, 
    this.phoneNumber,
    this.email,
    this.password, 
    this.icName,
    this.icNumber,
    this.icFrontImagePath, 
    this.bankStatementImagePath,
    this.businessName,
    this.address, 
    this.postcode,
    this.state
  });
}