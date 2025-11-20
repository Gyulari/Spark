class ParkingLot {
  final int managementNumber;
  final String name;
  final double longitude;
  final double latitude;
  final String type;
  final String? landlotAddress;
  final String? roadnameAddress;
  final int scale;
  final int count;
  final String price;
  final String base_time;
  final String base_fee;
  final String extra_time;
  final String extra_fee;
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
    required this.count,
    required this.price,
    required this.base_time,
    required this.base_fee,
    required this.extra_time,
    required this.extra_fee,
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
      count: map['count'] ?? 0,
      price: map['price'] ?? '',
      base_time: map['base_time'] ?? '',
      base_fee: map['base_fee'] ?? '',
      extra_time: map['extra_time'] ?? '',
      extra_fee: map['extra_fee'] ?? '',
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