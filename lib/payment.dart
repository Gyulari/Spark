import 'package:spark/app_import.dart';
import 'package:spark/reserve.dart';
import 'package:spark/style.dart';

class PaymentScreen extends StatefulWidget {
  final ParkingLot lot;
  final ParkingSpot spot;

  const PaymentScreen({
    super.key,
    required this.lot,
    required this.spot,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  TimeOfDay startTime = TimeOfDay.now();
  int usageHours = 2;

  bool _isPaymentSelected = false;

  Future<void> occupySpot({
    required int managementNumber,
    required String spotId,
  }) async
  {
    await SupabaseManager.client
        .from('parking_spots')
        .update({
          'is_occupied': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('management_number', managementNumber)
        .eq('spot_id', spotId);
  }

  Future<void> incrementLotCount(int managementNumber) async {
    await SupabaseManager.client.rpc(
      'increment_parking_count',
      params: {'p_management_number': managementNumber},
    );
  }

  Future<void> createReservation({
    required int managementNumber,
    required String spotId,
    required int usageHours,
  }) async
  {
    final now = DateTime.now();
    final end = now.add(Duration(hours: usageHours));

    await SupabaseManager.client.from('reservations').insert({
      'management_number': managementNumber,
      'spot_id': spotId,
      'start_time': now.toIso8601String(),
      'end_time': end.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 36.0),
          child: Column(
            children: [
              _buildSelectedSpotCard(),
              SizedBox(height: 20),
              _buildTimeSelectorCard(),
              SizedBox(height: 30),
              _buildReserveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSpotCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16.0),

          simpleText(
            '선택한 주차칸 : ${widget.spot.id}',
            32.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 16.0),

          simpleText(
            '사용자 : 일반인',
            24.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 20.0),

          if(!_isPaymentSelected) ...[
            SizedBox(
              width: 180.0,
              height: 48.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isPaymentSelected = true;
                  });
                },
                child: simpleText(
                  '결제 수단 선택',
                  20.0, FontWeight.bold, Colors.white, TextAlign.center
                ),
              ),
            )
          ],

          if(_isPaymentSelected) ...[
            simpleText(
              '결제방식 : 신용카드 결제 (--은행)',
              20.0, FontWeight.normal, Colors.black, TextAlign.center
            ),
          ],

          SizedBox(height: 24.0),

          simpleText(
            '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
            15.0, FontWeight.normal, Colors.grey[700]!, TextAlign.center
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectorCard() {
    return Container(
      padding: EdgeInsets.all(36.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          simpleText(
            '시간 설정',
            24.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 18),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
            margin: EdgeInsets.only(bottom: 14.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(36.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                simpleText(
                  '시작 시각',
                  18.0, FontWeight.bold, Colors.black, TextAlign.start
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _changeStartTime(-1),
                    ),
                    simpleText(
                      '${startTime.hour} 시 ${startTime.minute} 분',
                      18.0, FontWeight.bold, Colors.black, TextAlign.end
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _changeStartTime(1),
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 15),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
            margin: EdgeInsets.only(bottom: 14.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(36.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                simpleText(
                  '사용 시간',
                  18.0, FontWeight.bold, Colors.black, TextAlign.start
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: usageHours > 1
                            ? () => setState(() => usageHours--)
                            : null,
                        ),
                        simpleText(
                          '$usageHours 시간 00 분',
                          18.0, FontWeight.bold, Colors.black, TextAlign.start
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => setState(() => usageHours++),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeStartTime(int diff) {
    int h = startTime.hour + diff;
    if (h < 0) h = 23;
    if (h > 23) h = 0;

    setState(() {
      startTime = TimeOfDay(hour: h, minute: startTime.minute);
    });
  }

  Widget _buildReserveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          if(!_isPaymentSelected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Select your payment method')),
            );
            return;
          }

          await occupySpot(
            managementNumber: widget.lot.managementNumber,
            spotId: widget.spot.id,
          );

          await incrementLotCount(widget.lot.managementNumber);

          await createReservation(
            managementNumber: widget.lot.managementNumber,
            spotId: widget.spot.id,
            usageHours: usageHours
          );

          if(!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("예약이 시작되었습니다.")),
          );

          Navigator.pushNamed(context, '/home');
        },
        child: Text("예약 시작"),
      ),
    );
  }
}