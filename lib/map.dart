import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:spark/app_import.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:spark/style.dart';
import 'package:spark/reserve.dart';
import 'package:spark/provider.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  RoadLinkManager roadLinkManager = RoadLinkManager();
  StreamSubscription<Position>? _positionStream;

  late KakaoMapController mapController;
  final String kakaoRestApiKey = '5d85b804b65d01a8faf7acb5d95d8c76';

  bool _isGPSActive = false;
  bool _isRoadLinkActive = false;

  final _searchC = TextEditingController();

  LatLng curCenter = LatLng(37.5665, 126.9780);
  int curZoomLevel = 5;

  LatLng? curUserPos;
  bool _hasCenteredToUser = false;

  Set<Marker> lotMarkers = {};
  Set<Marker> curPosMarker = {};
  Set<Marker> markers = {};
  Set<CustomOverlay> lotOverlays = {};
  Set<CustomOverlay> overlays = {};

  Set<String> curRegions = {};
  List<String> curRoadsInBound = [];
  List<Polyline> polylines = [];

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
      lotOverlays = lotsData.map((l) {
        final addressText = l.displayAddress.isNotEmpty
          ? l.displayAddress
          : '주소 정보 없음';

        final occupied = l.count / l.scale;
        final colorClass = occupied >= 0.8 ? 'orange' : 'blue';

        return CustomOverlay(
          customOverlayId: l.managementNumber.toString(),
          latLng: LatLng(l.latitude, l.longitude),
          content: '<div class="parking-overlay $colorClass"><span>${l.count}/${l.scale}</span></div><style>.parking-overlay {display: flex;align-items: center;justify-content: center;padding: 6px 12px;color: white;font-weight: bold;font-size: 22px;border-radius: 6px;box-shadow: 0 2px 4px rgba(0,0,0,0.3);white-space: nowrap;}.parking-overlay.blue {background-color: #2D9CDB;}.parking-overlay.orange {background-color: #F2994A;}</style>',
          xAnchor: 0.0,
          yAnchor: 0.0,
        );
      }).toSet();

      overlays = {...lotOverlays};
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

  Future<ParkingLot?> _getParkingLotByOverlayId(String overlayId) async {
    final res = await SupabaseManager.client
        .from('PublicParkingLot')
        .select('*')
        .eq('management_number', int.parse(overlayId))
        .maybeSingle();

    if(res == null) return null;
    return ParkingLot.fromMap(res);
  }

  Future<void> updateRegions(LatLngBounds bounds) async {
    if(curZoomLevel >= 5) return;

    final newRegions = await getRegionsInBounds(bounds);

    final preRegions = Set<String>.from(curRegions);
    final regionsToRemove = preRegions.difference(newRegions);

    for(var region in regionsToRemove) {
      roadLinkManager.removePolylinesForRegion(region);
      polylines = roadLinkManager.allRoadLinks;
    }

    curRegions.clear();

    for(final region in newRegions) {
      curRegions.add(region);

      if(!preRegions.contains(region)) {
        final newRoadLinks = await loadRoadsForRegion(region);
        roadLinkManager.addPolylinesForRegion(region, newRoadLinks);
        polylines = roadLinkManager.allRoadLinks;
      }
    }
  }

  Future<Set<String>> getRegionsInBounds(LatLngBounds bounds) async {
    List<String> foundRegions = [];

    const double step = 0.02;

    for(double lat = bounds.getSouthWest().latitude; lat <= bounds.getNorthEast().latitude; lat += step) {
      for(double lng = bounds.getSouthWest().longitude; lng <= bounds.getNorthEast().longitude; lng += step) {
        final res = await http.get(
          Uri.parse('https://dapi.kakao.com/v2/local/geo/coord2regioncode.json?x=$lng&y=$lat'),
          headers: {"Authorization": "KakaoAK $kakaoRestApiKey"},
        );

        if(res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final doc = data['documents']?[0];

          if(doc != null) {
            final region = '${doc['region_1depth_name']}/${doc['region_2depth_name']}';
            foundRegions.add(region);
          }
        } else {
          debugPrint('Failed to call API for searching region information');
        }

        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    return foundRegions.toSet();
  }

  Future<List<Polyline>> loadRoadsForRegion(String region) async {
    var regionParts = region.split('/');
    var region_1depth = regionParts[0], region_2depth = regionParts[1];

    final rows = await fetchRoadNamesByRegion(region_1depth, region_2depth);

    List<Polyline> roadLinks = [];

    for(var roadName in rows) {
      final lines = await fetchRoadGeometry(roadName);

      for(final points in lines) {
        if(points.isNotEmpty) {
          roadLinks.add(
            Polyline(
              polylineId: UniqueKey().toString(),
              points: points,
              strokeColor: Colors.red,
              strokeWidth: 3,
            )
          );
        }
      }
    }

    return roadLinks;
  }

  Future<List<String>> fetchRoadNamesByRegion(String region, String city) async {
    final res = await SupabaseManager.client
        .from('road_parking_restrict_zone')
        .select('road_name')
        .eq('region', region)
        .eq('city', city);

    final roadNames = (res as List)
      .map((row) => row['road_name'] as String)
      .where((roadName) => roadName.endsWith('로'))
      .toSet();

    return roadNames.toList();
  }

  Future<List<List<LatLng>>> fetchRoadGeometry(String roadName) async {
    if(!roadName.endsWith('로')) return [];

    final serviceKey = '1A45061F-99E8-35B1-ACB7-D5EB23C7D897';  // VWorld Service Key
    final String bbox = '125.04,33.06,131.52,38.27';
    final attr= Uri.encodeQueryComponent('road_name:like:$roadName');

    final url = Uri.parse(
        'https://api.vworld.kr/req/data?'
            'service=data'
            '&version=2.0'
            '&request=GetFeature'
            '&data=LT_L_MOCTLINK'
            '&format=json'
            '&key=$serviceKey'
            '&domain=localhost'
            '&crs=EPSG:4326'
            '&geometry=true'
            '&geomFilter=BOX($bbox)'
            '&attrFilter=$attr'
            '&size=100'
    );

    final res = await http.get(url);
    final body = utf8.decode(res.bodyBytes);

    if(!body.trim().startsWith('{')) {
      debugPrint('It is not JSON:\n$body');
      return [];
    }

    final data = jsonDecode(body);

    if(data['response']?['status'] != 'OK') {
      debugPrint('VWorld API Error: ${data['response']?['error']}');
      return [];
    }

    final features = data['response']?['result']?['featureCollection']?['features'] ?? [];

    List<List<LatLng>> allLinks = [];

    for(final f in features) {
      final props = f['properties'];
      if(props == null) continue;

      if(props['road_name']?.toString() != roadName) continue;

      final geom = f['geometry'];
      if(geom == null || geom['coordinates'] == null) continue;

      for(final line in geom['coordinates']) {
        final points = (line as List)
            .map((pair) => LatLng(pair[1], pair[0]))
            .toList();
        allLinks.add(points);
      }
    }

    return allLinks;
  }

  void _toggleRoadLinks() {
    setState(() {
      if(_isRoadLinkActive) {
        _isRoadLinkActive = false;
      }
      else {
        _isRoadLinkActive = true;
      }
    });
  }

  Future<void> focusLotInfo(ParkingLot lot) async {
    debugPrint('Hey');
    mapController.setCenter(LatLng(lot.latitude, lot.longitude));

    _showParkingLotInfoDialog(
      context,
      lot: lot,
      onClose: () {
        setState(() {
          _parkingLotInfoLoading = false;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        KakaoMap(
          onMapCreated: ((controller) async {
            mapController = controller;
            final focusLot = context.read<FocusLotState>().focusLot;
            if(focusLot != null) {
              focusLotInfo(focusLot);
              context.read<FocusLotState>().clear();
            }
            final curBounds = await mapController.getBounds();
            _loadParkingLotsMarkers(curBounds);
          }),
          onCameraIdle: (LatLng center, int zoomLevel) async {
            setState(() {
              curZoomLevel = zoomLevel;
            });

            final curBounds = await mapController.getBounds();

            if(zoomLevel < 5) {
              _loadParkingLotsMarkers(curBounds);
            } else {
              setState(() {
                lotMarkers.clear();
                markers = {...curPosMarker};
                mapController.clearMarker(markerIds: markers.map((e) => e.markerId).toList());
                overlays.clear();
              });
            }

            updateRegions(curBounds);
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
          polylines: (_isRoadLinkActive && curZoomLevel < 5) ? polylines : [],
          customOverlays: overlays.toList(),
          onCustomOverlayTap: (String overlayId, LatLng latLng) async {
            if(_parkingLotInfoLoading) return;

            setState(() {
              _parkingLotInfoLoading = true;
            });

            final lot = await _getParkingLotByOverlayId(overlayId);

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
          }
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

        Positioned(
          top: 150.0,
          right: 16.0,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () async {
              _toggleRoadLinks();
            },
            child: Icon(
              _isRoadLinkActive ? Icons.map : Icons.map_outlined,
              color: _isRoadLinkActive ? Colors.blueAccent : Colors.grey[400],
            ),
          ),
        )
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

class ParkingLotInfoDialog extends StatefulWidget {
  final ParkingLot lot;
  final VoidCallback? onClose;

  const ParkingLotInfoDialog({
    super.key,
    required this.lot,
    this.onClose,
  });

  @override
  State<ParkingLotInfoDialog> createState() => _ParkingLotInfoDialogState();
}

class _ParkingLotInfoDialogState extends State<ParkingLotInfoDialog> {
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteStatus();
  }

  Future<void> loadFavoriteStatus() async {
    final status = await isFavorite(widget.lot.managementNumber);
    setState(() {
      isFav = status;
    });
  }

  Future<bool> isFavorite(int managementNumber) async {
    final user = SupabaseManager.client.auth.currentUser;
    if(user == null) return false;

    final res = await SupabaseManager.client
        .from('user_favorites')
        .select()
        .eq('user_id', user.id)
        .eq('management_number', managementNumber);

    return res.isNotEmpty;
  }

  Future<void> toggleFavorite(int managementNumber, bool currentlyFav) async {
    final user = SupabaseManager.client.auth.currentUser;
    if(user == null) return;

    if(currentlyFav) {
      await SupabaseManager.client
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('management_number', managementNumber);
    } else {
      await SupabaseManager.client.from('user_favorites').insert({
        'user_id': user.id,
        'management_number': managementNumber,
      });
    }
  }

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

                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.yellow[700] : Colors.grey,
                      size: 28.0,
                    ),
                    onPressed: () async {
                      await toggleFavorite(widget.lot.managementNumber, isFav);
                      loadFavoriteStatus();
                    },
                  ),

                  InkWell(
                    borderRadius: BorderRadius.circular(20.0),
                    onTap: () {
                      Navigator.of(context).maybePop();
                      widget.onClose?.call();
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
              trailingText: widget.lot.name,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.domain,
              label: '주차장 유형',
              trailingText: widget.lot.type,
            ),

            divider(),

            if(widget.lot.price == '무료' || widget.lot.base_time == '0') ...[
              ParkingLotInfoRow(
                icon: Icons.attach_money_rounded,
                label: '요금',
                trailingText: '무료',
              ),
            ],

            if(widget.lot.price == '유료' && widget.lot.base_time != '0') ...[
              divider(),

              ParkingLotInfoRow(
                icon: Icons.attach_money_rounded,
                label: '기본 요금',
                trailingText: '${widget.lot.base_time}분 - ${widget.lot.base_fee}원',
              ),

              divider(),

              ParkingLotInfoRow(
                icon: Icons.attach_money_rounded,
                label: '추가 요금',
                trailingText: '${widget.lot.extra_time}분당 ${widget.lot.extra_fee}',
              ),
            ],

            divider(),

            ParkingLotInfoRow(
              icon: Icons.phone,
              label: '연락처',
              trailingText: widget.lot.contact,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.place,
              label: '주소',
              trailingText: widget.lot.displayAddress,
            ),

            divider(),

            ParkingLotInfoRow(
              icon: Icons.directions_car,
              label: '주차 대수',
              trailingText: '${widget.lot.count}/${widget.lot.scale}대',
            ),

            SizedBox(height: 16.0),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationScreen(lot: widget.lot),
                      )
                    );
                  },
                  child: simpleText(
                    '예약하기',
                    16.0, FontWeight.bold, Colors.white, TextAlign.center
                  ),
                ),
              )
            )
          ],
        ),
      ),
    );
  }
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

class RoadLinkManager {
  Map<String, List<Polyline>> roadLinksForRegion = {};

  void addPolylinesForRegion(String regionName, List<Polyline> newRoadLinks) {
    if(!roadLinksForRegion.containsKey(regionName)) {
      roadLinksForRegion[regionName] = newRoadLinks;
    }
  }

  void removePolylinesForRegion(String regionName) {
    if(roadLinksForRegion.containsKey(regionName)) {
      roadLinksForRegion[regionName]?.clear();
      roadLinksForRegion.remove(regionName);
    }
  }

  List<Polyline> get allRoadLinks {
    List<Polyline> allRoadLinks = [];
    roadLinksForRegion.forEach((key, value){
      allRoadLinks.addAll(value);
    });
    return allRoadLinks;
  }
}