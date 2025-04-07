enum EncodingType { ean8, ean13, qr }

class GlobalData {
  GlobalData._privateConstructor();

  static final GlobalData instance = GlobalData._privateConstructor();

  List<String> codes = [];
  EncodingType? encodingType;
}
