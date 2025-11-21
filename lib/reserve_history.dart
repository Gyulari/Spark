import 'package:spark/app_import.dart';
import 'package:spark/style.dart';

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  State<ReserveHistory> createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory> {
  Future<List<Map<String, dynamic>>> fetchReserveHistory() async {
    final user = SupabaseManager.client.auth.currentUser;

    if(user == null) return [];

    final res = await SupabaseManager.client
        .from('reservations')
        .select()
        .eq('user_id', user.id)
        .order('start_time', ascending: false);

    List<Map<String, dynamic>> withLotInfo = [];

    for(final r in res) {
      final lot = await fetchLotInfoByReservation(r['management_number']);
      withLotInfo.add({
        'reservation': r,
        'lot': lot,
      });
    }

    return withLotInfo;
  }

  Future<ParkingLot?> fetchLotInfoByReservation(int managementNumber) async {
    final res = await SupabaseManager.client
        .from('PublicParkingLot')
        .select()
        .eq('management_number', managementNumber)
        .maybeSingle();

    if(res == null) return null;

    return ParkingLot.fromMap(res);
  }

  String formatKoreanDate(String isoString) {
    final date = DateTime.parse(isoString);

    return '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour}시 ${date.minute.toString().padLeft(2, '0')}분';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.blue[700],
            flexibleSpace: FlexibleSpaceBar(
              title: simpleText(
                '예약 내역',
                24.0, FontWeight.bold, Colors.white, TextAlign.start
              ),
              titlePadding: EdgeInsetsDirectional.only(start: 32.0, bottom: 16.0),
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchReserveHistory(),
            builder: (context, snapshot) {
              if(!snapshot.hasData) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final items = snapshot.data!;
              if(items.isEmpty){
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('최근 예약 내역이 없습니다.')),
                  )
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: items.length,
                    (context, i) {
                      final reservation = items[i]['reservation'];
                      final lot = items[i]['lot'];
                      final startTime = formatKoreanDate(reservation['start_time']);
                      final endTime = formatKoreanDate(reservation['end_time']);

                      return Container(
                        margin: EdgeInsets.all(12.0),
                        padding: EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 주차장 이름, 주차칸, 시작시간, 종료시간, 총 요금
                            simpleText(
                              '${lot.name}',
                              18.0, FontWeight.bold, Colors.black, TextAlign.start
                            ),
                            SizedBox(height: 8.0),

                            Divider(
                              height: 1.0,
                              thickness: 2.0,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8.0),

                            simpleText(
                              '유형 : ${lot.type}',
                              18.0, FontWeight.normal, Colors.black, TextAlign.start
                            ),
                            SizedBox(height: 8.0),

                            simpleText(
                              '주차한 칸 : ${reservation['spot_id']}',
                              18.0, FontWeight.normal, Colors.black, TextAlign.start
                            ),
                            SizedBox(height: 8.0),

                            simpleText(
                              '시작 시각 : $startTime',
                              18.0, FontWeight.normal, Colors.black, TextAlign.start
                            ),
                            SizedBox(height: 8.0),

                            simpleText(
                              '종료 시각 : $endTime',
                              18.0, FontWeight.normal, Colors.black, TextAlign.start
                            ),
                            SizedBox(height: 8.0),
                          ],
                        ),
                      );
                    }
                )
              );
            }
          )
        ]
      )
    );
  }
}