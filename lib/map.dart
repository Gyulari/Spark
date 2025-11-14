import 'package:http/http.dart' as http;
import 'package:spark/app_import.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

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

  Set<Marker> curPosMarker = {};
  Set<Marker> markers = {};

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
      markers = curPosMarker;
    });
  }

  void _removeCurPosMarker() async {
    setState(() {
      curPosMarker.clear();
      markers = {};
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        KakaoMap(
          onMapCreated: ((controller) async {
            mapController = controller;
          }),
          onCameraIdle: (LatLng center, int zoomLevel) {

          },
          center: curCenter,
          currentLevel: 3,
          zoomControl: true,
          zoomControlPosition: ControlPosition.bottomRight,
          markers: markers.toList(),
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