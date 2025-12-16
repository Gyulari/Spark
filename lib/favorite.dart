import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:spark/provider.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  Future<List<ParkingLot>> fetchFavorites() async {
    final user = SupabaseManager.client.auth.currentUser;
    if(user == null) return [];

    final favRows = await SupabaseManager.client
        .from('user_favorites')
        .select('management_number')
        .eq('user_id', user.id);

    final List<int> favIds = favRows.map<int>((row) => row['management_number'] as int).toList();

    if(favIds.isEmpty) return [];

    final lots = await SupabaseManager.client
        .from('PublicParkingLot')
        .select()
        .inFilter('management_number', favIds);

    return lots.map<ParkingLot>((row) => ParkingLot.fromMap(row)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.yellow[800],
            flexibleSpace: FlexibleSpaceBar(
              title: simpleText(
                '즐겨찾기',
                24.0, FontWeight.bold, Colors.white, TextAlign.start
              ),
              titlePadding: EdgeInsetsDirectional.only(start: 32.0, bottom: 16.0),
            ),
          ),

          FutureBuilder<List<ParkingLot>>(
            future: fetchFavorites(),
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
              if(items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('즐겨찾기한 주차장이 없습니다.')),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: items.length,
                    (context, i) {
                      final lot = items[i];
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
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              simpleText(
                                  lot.name,
                                  18.0, FontWeight.bold, Colors.black, TextAlign.start
                              ),
                              SizedBox(height: 8.0),

                              Divider(
                                height: 1.0,
                                thickness: 2.0,
                                color: Colors.grey
                              ),
                              SizedBox(height: 8.0),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.local_parking, size: 18.0, color: Colors.yellow[800]),
                                  SizedBox(width: 8.0),
                                  simpleText(
                                      '유형 : ${lot.type}',
                                      18.0, FontWeight.bold, Colors.black, TextAlign.start
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.money, size: 18.0, color: Colors.yellow[800]),
                                  SizedBox(width: 8.0),
                                  simpleText(
                                      '요금 : ${lot.price}',
                                      18.0, FontWeight.bold, Colors.black, TextAlign.start
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.call, size: 18.0, color: Colors.yellow[800]),
                                  SizedBox(width: 8.0),
                                  simpleText(
                                      '유형 : ${lot.contact}',
                                      18.0, FontWeight.bold, Colors.black, TextAlign.start
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.place, size: 18.0, color: Colors.yellow[800]),
                                  SizedBox(width: 8.0),
                                  simpleText(
                                      '주소 : ${lot.displayAddress}',
                                      18.0, FontWeight.bold, Colors.black, TextAlign.start
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),

                              SizedBox(height: 10.0),
                              Divider(height: 1.0, color: Color(0xFFE0E0E0)),
                              SizedBox(height: 10.0),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.directions_car, size: 18.0, color: Colors.yellow[800]),
                                  SizedBox(width: 8.0),
                                  simpleText(
                                      '주차 대수 : ${lot.count} / ${lot.scale}',
                                      18.0, FontWeight.bold, Colors.black, TextAlign.start
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),

                              SizedBox(height: 12.0),
                              Row(
                                children: [
                                  Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow[800],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24.0),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.read<NavState>().setSelectedIndex(0);
                                      context.read<FocusLotState>().setFocusLot(lot);
                                    },
                                    child: Text('주차장 바로가기'),
                                  ),
                                ],
                              )
                            ],
                          )
                      );
                    }
                ),
              );
            }
          )
        ],
      ),
    );
  }
}