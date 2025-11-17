import 'package:http/http.dart' as http;
import 'package:spark/app_import.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:spark/parking_lot.dart';
import 'package:spark/style.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late KakaoMapController mapController;

  StreamSubscription<Position>? _positionStream;
  bool _isGPSActive = false;

  final _searchC = TextEditingController();

  LatLng curCenter = LatLng(37.5665, 126.9780);
  LatLng? curUserPos;
  bool _hasCenteredToUser = false;

  Set<Marker> lotMarkers = {};
  Set<Marker> curPosMarker = {};
  Set<Marker> markers = {};

  ParkingLot? selectedLot;

  bool _parkingLotInfoLoading = false;

  Future<List<LatLng>> _keywordSearch(String keyword) async {
    const apiKey = '5d85b804b65d01a8faf7acb5d95d8c76';
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword',
    );

    final res = await http.get(url, headers: {
      'Authorization': 'KakaoAK $apiKey',
    });

    if(res.statusCode == 200){
      final data = jsonDecode(res.body);
      final List docs = data['documents'];

      return docs.map((doc) {
        final x = double.parse(doc['x']);
        final y = double.parse(doc['y']);
        return LatLng(y, x);
      }).toList();
    } else {
      throw Exception('검색 실패: ${res.statusCode}');
    }
  }

  void _startListeningLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!mounted) return;

    if(!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activate GPS on options first')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) {
        throw Exception('Denied GPS permission');
      }
    }

    if(permission == LocationPermission.deniedForever) {
      throw Exception('GPS Permission is denied permanently.');
    }

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        curUserPos = LatLng(position.latitude, position.longitude);
      });

      _updateCurrentUserPosition(position);

      if(!_hasCenteredToUser) {
        mapController.setCenter(
          LatLng(position.latitude, position.longitude)
        );

        _hasCenteredToUser = true;
      }
    });

    setState(() {
      _isGPSActive = true;
    });
  }

  void _stopListeningLocation() {
    _positionStream?.cancel();
    _positionStream = null;

    setState(() {
      _isGPSActive = false;
      curUserPos = null;
    });
  }

  void _updateCurrentUserPosition(Position pos) async {
    final latLng = LatLng(pos.latitude, pos.longitude);

    mapController.setCenter(latLng);

    final icon = await MarkerIcon.fromAsset('assets/icons/user_icon_pos.png');

    setState(() {
      final curPos = Marker(
        markerId: 'userDot_${DateTime.now().millisecondsSinceEpoch}',
        latLng: latLng,
        icon: icon,
        width: 48,
        height: 48,
      );

      curPosMarker.clear();
      curPosMarker.add(curPos);
      markers = {...lotMarkers, ...curPosMarker};
    });
  }

  void _removeCurPosMarker() async {
    setState(() {
      curPosMarker.clear();
      markers = {...lotMarkers};
    });

    mapController.clearMarker(markerIds: markers.map((e) => e.markerId).toList());
  }

  void _toggleGPS() {
    if(_isGPSActive) {
      _stopListeningLocation();
      _removeCurPosMarker();

      setState(() {
        _hasCenteredToUser = false;
      });
    } else {
      _startListeningLocation();
    }
  }

  Future<void> _loadParkingLotsMarkers(LatLngBounds bounds) async {
    final lotsData = await fetchParkingLotsInBounds(bounds);

    setState(() {
      lotMarkers = lotsData.map((l) {
        final addressText = l.displayAddress.isNotEmpty
          ? l.displayAddress
          : '주소 정보 없음';

        return Marker(
          markerId: l.managementNumber.toString(),
          latLng: LatLng(l.latitude, l.longitude),
        );
      }).toSet();

      markers = {...lotMarkers, ...curPosMarker};
    });
  }

  Future<List<ParkingLot>> fetchParkingLotsInBounds(LatLngBounds bounds) async {
    final res = await SupabaseManager.client
        .from('PublicParkingLot')
        .select('*')
        .gte('latitude', bounds.getSouthWest().latitude)
        .lte('latitude', bounds.getNorthEast().latitude)
        .gte('longitude', bounds.getSouthWest().longitude)
        .lte('longitude', bounds.getNorthEast().longitude);

    return (res as List)
        .map((e) => ParkingLot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _showParkingLotInfoDialog(
    BuildContext context, {
      required ParkingLot lot,
      VoidCallback? onClose,
      bool barrierDismissible = false,
  })
  {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'ParkingLotInfo',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return Center(
          child: ParkingLotInfoDialog(
            lot: lot,
            onClose: onClose,
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }

  Future<ParkingLot?> _getParkingLotByMarkerId(String markerId) async {
    final res = await SupabaseManager.client
        .from('PublicParkingLot')
        .select('*')
        .eq('management_number', int.parse(markerId))
        .maybeSingle();

    if(res == null) return null;
    return ParkingLot.fromMap(res);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        KakaoMap(
          onMapCreated: ((controller) async {
            mapController = controller;
            mapController.getBounds().then((bounds) {
              _loadParkingLotsMarkers(bounds);
            });
            // final bounds = await mapController.getBounds();
            // await _loadParkingLotsMarkers(bounds);
          }),
          onCameraIdle: (LatLng center, int zoomLevel) {
            if(zoomLevel < 5) {
              mapController.getBounds().then((bounds) {
                _loadParkingLotsMarkers(bounds);
              });
            } else {
              setState(() {
                lotMarkers.clear();
                markers = {...curPosMarker};
                mapController.clearMarker(markerIds: markers.map((e) => e.markerId).toList());
              });
            }
          },
          center: curCenter,
          currentLevel: 3,
          zoomControl: true,
          zoomControlPosition: ControlPosition.bottomRight,
          markers: markers.toList(),
          onMarkerTap: (markerId, latLng, level) async {
            if(_parkingLotInfoLoading) return;

            setState(() {
              _parkingLotInfoLoading = true;
            });

            final lot = await _getParkingLotByMarkerId(markerId);

            if(!context.mounted || lot == null) return;

            _showParkingLotInfoDialog(
              context,
              lot: lot,
              onClose: () {
                setState(() {
                  _parkingLotInfoLoading = false;
                });
              }
            );

            setState(() {
              selectedLot = lot;
            });
          },
          polylines: []
        ),

        SafeArea(
          child: MapSearchBar(
            controller: _searchC,
            onSearch: (keyword) async {
              final res = await _keywordSearch(keyword);

              if(res.isEmpty) return;

              setState(() {
                markers = res
                    .map((pos) => Marker(
                        markerId: UniqueKey().toString(),
                        latLng: pos,
                )).toSet();
              });

              mapController.fitBounds(res);
            },
          ),
        ),

        Positioned(
          top: 75.0,
          right: 16.0,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _toggleGPS,
            child: Icon(
              _isGPSActive ? Icons.gps_fixed : Icons.gps_off,
              color: _isGPSActive ? Colors.blueAccent : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onSearch;

  const MapSearchBar({
    super.key,
    required this.controller,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.0),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: '장소를 검색하세요',
          hintStyle: TextStyle(fontSize: 16.0, color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
      ),
    );
  }
}

class ParkingLotInfoDialog extends StatelessWidget {
  final ParkingLot lot;
  final VoidCallback? onClose;

  const ParkingLotInfoDialog({
    super.key,
    required this.lot,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        padding: EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18.0,
              offset: Offset(0, 8)
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Row(
                children: [
                  simpleText(
                    '주차장 정보',
                    16.0, FontWeight.bold, Colors.black, TextAlign.start
                  ),

                  Spacer(),

                  InkWell(
                    borderRadius: BorderRadius.circular(20.0),
                    onTap: () {
                      Navigator.of(context).maybePop();
                      onClose?.call();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close, size: 20.0, color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 8.0),

            ParkingLotInfoRow(
              icon: Icons.local_parking,
              label: '주차장 이름',
              trailingText: lot.name,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.domain,
              label: '주차장 유형',
              trailingText: lot.type,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.attach_money_rounded,
              label: '요금',
              trailingText: lot.price,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.phone,
              label: '연락처',
              trailingText: lot.contact,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.place,
              label: '주소',
              trailingText: lot.displayAddress,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.directions_car,
              label: '최대 주차 가능 대수',
              trailingText: '${lot.scale}대',
            ),

            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
  // name, type, price, contact, address, scale,
}

class ParkingLotInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailing;

  const ParkingLotInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: Colors.black),
          SizedBox(width: 10.0),
          Expanded(
            child: simpleText(
              label,
              16.0, FontWeight.normal, Colors.black, TextAlign.start
            ),
          ),

          if(trailing != null)
            trailing!,

          if(trailingText != null) ...[
            simpleText(
              trailingText!,
              16.0, FontWeight.normal, Colors.black, TextAlign.start
            ),
          ],
        ],
      ),
    );
  }
}