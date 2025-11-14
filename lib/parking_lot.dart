class ParkingLot {
  final int managementNumber;
  final String name;
  final double longitude;
  final double latitude;
  final String type;
  final String? landlotAddress;
  final String? roadnameAddress;
  final int scale;
  final String price;
  final String contact;

  ParkingLot({
    required this.managementNumber,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.type,
    this.landlotAddress,
    this.roadnameAddress,
    required this.scale,
    required this.price,
    required this.contact,
  });

  factory ParkingLot.fromMap(Map<String, dynamic> map){
    return ParkingLot(
      managementNumber: map['management_number'] ?? 0,
      name: map['name'] ?? '',
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? '',
      landlotAddress: map['landlot_address'],
      roadnameAddress: map['roadname_address'],
      scale: map['scale'] ?? 0,
      price: map['price'] ?? '',
      contact: map['contact'] ?? '',
    );
  }

  String get displayAddress {
    if(roadnameAddress != null && roadnameAddress!.isNotEmpty){
      return roadnameAddress!;
    }
    else if(landlotAddress != null && landlotAddress!.isNotEmpty){
      return landlotAddress!;
    }
    else{
      return '';
    }
  }
}