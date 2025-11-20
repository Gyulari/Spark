import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:spark/payment.dart';

class ReservationScreen extends StatefulWidget{
  final ParkingLot lot;

  const ReservationScreen({super.key, required this.lot});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late ParkingLot lot;
  late VideoPlayerController _vController;

  late Future<List<ParkingSpot>> _spotsFuture;

  @override
  void initState() {
    super.initState();

    lot = widget.lot;

    _vController = VideoPlayerController.asset('assets/videos/test_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _vController.play();
        _vController.setLooping(true);
      });

    _spotsFuture = loadSpots();
  }

  Future<List<ParkingSpot>> loadSpots() async {
    final existingSpots = await fetchParkingSpots(lot.managementNumber);

    if(existingSpots.isNotEmpty) {
      debugPrint('Using DB');
      return existingSpots;
    }

    debugPrint('Using Generator');
    final generated = generateTestSpots(
      scale: lot.scale,
      count: lot.count,
    );

    await saveGeneratedSpots(lot.managementNumber, generated);

    debugPrint('Save TestSpots to DB');

    return generated;
  }

  Future<List<ParkingSpot>> fetchParkingSpots(int managementNumber) async {
    final res = await SupabaseManager.client
        .from('parking_spots')
        .select()
        .eq('management_number', managementNumber);

    if(res.isEmpty) return [];

    return res.map((row) => ParkingSpot.fromMap(row)).toList();
  }

  Future<void> saveGeneratedSpots(int managementNumber, List<ParkingSpot> spots) async {
    final payload = spots.map((s) {
      return {
        'management_number': managementNumber,
        'spot_id': s.id,
        'is_occupied': s.isOccupied,
        'is_priority': s.isPriority,
      };
    }).toList();

    await SupabaseManager.client.from('parking_spots').insert(payload);
  }

  List<ParkingSpot> generateTestSpots ({
    required int scale,
    required int count,
  })
  {
    final List<ParkingSpot> spots = [];
    final random = Random();

    for(int i=1; i<=scale; i++) {
      spots.add(
        ParkingSpot(
          id: "P${i.toString().padLeft(2, '0')}",
          isOccupied: false,
          isPriority: false,
        )
      );
    }

    List<int> occupiedIndexes = [];
    while(occupiedIndexes.length < count) {
      int index = random.nextInt(scale);
      if(!occupiedIndexes.contains(index)) {
        occupiedIndexes.add(index);
        spots[index] = ParkingSpot(
          id: spots[index].id,
          isOccupied: true,
          isPriority: false,
        );
      }
    }

    int priorityCount = (scale / 10).floor();
    List<int> priorityIndexes = [];
    while(priorityIndexes.length < priorityCount) {
      int index = random.nextInt(scale);
      if(!priorityIndexes.contains(index)) {
        priorityIndexes.add(index);

        final s = spots[index];
        spots[index] = ParkingSpot(
          id: s.id,
          isOccupied: s.isOccupied,
          isPriority: true,
        );
      }
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lot.name),
      ),
      body: FutureBuilder<List<ParkingSpot>>(
        future: _spotsFuture,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final spots = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                buildVideoArea(lot),
                SizedBox(height: 20.0),
                ParkingSpotSelector(
                  lot: lot,
                  spots: spots,
                )
              ],
            )
          );
        },
      ),
    );
  }

  Widget buildVideoArea(ParkingLot lot) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12.0,
            offset: Offset(0, 6),
          ),
        ],
      ),      
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          simpleText(
            '${lot.name} 실시간 CCTV',
            24.0, FontWeight.bold, Colors.black, TextAlign.center
          ),
          SizedBox(height: 16.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: _vController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _vController.value.aspectRatio,
                    child: VideoPlayer(_vController),
                  )
                : Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class ParkingSpot {
  final String id;
  final bool isOccupied;
  final bool isPriority;

  ParkingSpot({
    required this.id,
    required this.isOccupied,
    required this.isPriority,
  });

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['spot_id'],
      isOccupied: map['is_occupied'],
      isPriority: map['is_priority'],
    );
  }
}

class ParkingSpotSelector extends StatefulWidget {
  final ParkingLot lot;
  final List<ParkingSpot> spots;

  const ParkingSpotSelector({super.key, required this.lot, required this.spots});

  @override
  State<ParkingSpotSelector> createState() => _ParkingSpotSelectorState();
}

class _ParkingSpotSelectorState extends State<ParkingSpotSelector> {
  bool needPrioritySpot = false;
  ParkingSpot? selectedSpot;

  @override
  Widget build(BuildContext context) {
    List<ParkingSpot> filteredSpots = widget.spots.where((spot) {
      if(needPrioritySpot) {
        return spot.isPriority;
      } else {
        return !(spot.isPriority);
      }
    }).toList();

    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: needPrioritySpot,
                onChanged: (value) {
                  setState(() {
                    needPrioritySpot = value!;
                    selectedSpot = null;
                  });
                },
              ),
              simpleText(
                  '약자 우선 주차칸을 필요로 하시나요?',
                  18.0, FontWeight.normal, Colors.black, TextAlign.start
              ),
            ],
          ),

          SizedBox(height: 10.0),

          DropdownButtonFormField<ParkingSpot>(
            value: selectedSpot,
            hint: Text('주차 칸을 선택하세요'),
            items: filteredSpots.map((spot) {
              final label = spot.isOccupied
                  ? '${spot.id} (주차 중)'
                  : '${spot.id} (주차 가능)';

              return DropdownMenuItem(
                value: spot,
                enabled: !spot.isOccupied,
                child: simpleText(
                    label,
                    16.0, FontWeight.bold, spot.isOccupied ? Colors.red : Colors.black, TextAlign.start
                ),
              );
            }).toList(),
            onChanged: (spot) {
              if(spot != null && spot.isOccupied) {
                return;
              }

              setState(() {
                selectedSpot = spot;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
            ),
          ),

          buildSelectedSpotResult(selectedSpot),
        ],
      )
    );
  }

  Widget buildSelectedSpotResult(ParkingSpot? spot) {
    if(spot == null) return SizedBox.shrink();

    final String typeLabel = spot.isPriority ? '(약자 우선 주차칸)' : '(일반 주차칸)';

    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.0),

          simpleText(
            spot.id,
            40.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          simpleText(
            typeLabel,
            18.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 40.0),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      lot: widget.lot,
                      spot: spot,
                    )
                  )
                );
              },
              child: simpleText(
                '이 주차칸으로 예약하기',
                18.0, FontWeight.bold, Colors.white, TextAlign.center
              ),
            ),
          )
        ],
      ),
    );
  }
}