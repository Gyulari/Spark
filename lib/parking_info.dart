import 'package:spark/app_import.dart';
import 'package:spark/style.dart';

class ParkingInfo extends StatefulWidget {
  const ParkingInfo({super.key});

  @override
  State<ParkingInfo> createState() => _ParkingInfoState();
}

class _ParkingInfoState extends State<ParkingInfo> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.green[300],
            flexibleSpace: FlexibleSpaceBar(
              title: simpleText(
                '주차 정보',
                24.0, FontWeight.bold, Colors.white, TextAlign.start
              ),
              titlePadding: EdgeInsetsDirectional.only(start: 32.0, bottom: 16.0),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('SPARK 주차 정보'),
                  SizedBox(height: 24.0),

                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 3.0,
                          color: Colors.grey.withAlpha(25),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.green, size: 24.0),
                            SizedBox(width: 10.0),
                            simpleText(
                              '갓길 차선 표시로 주정차 여부 확인하기',
                              20.0, FontWeight.bold, Colors.green, TextAlign.start
                            ),
                          ],
                        ),

                        SizedBox(height: 24.0),

                        Image.asset(
                          'assets/shoulder_parking_info.png',
                          width: screenWidth,
                          fit: BoxFit.cover,
                        ),

                        SizedBox(height: 24.0),

                        SizedBox(height: 12.0),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...['흰색실선 : 주정차가 가능해요!', '황색점선 : 5분 이내의 정차만 가능해요!', '황색실선 : 요일과 시간에 따라 탄력적으로 주정차가 가능해요!', '황색 복선 : 절대로 주정차 하시면 안돼요!'].map((text) => _featureRow(text, Colors.green)),
                          ],
                        ),
                      ],
                    )
                  ),

                  SizedBox(height: 16.0),

                  Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3.0,
                            color: Colors.grey.withAlpha(25),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.green, size: 24.0),
                              SizedBox(width: 10.0),
                              simpleText(
                                  '주정차가 불가능한 위치 확인하기',
                                  20.0, FontWeight.bold, Colors.green, TextAlign.start
                              ),
                            ],
                          ),

                          SizedBox(height: 24.0),

                          Image.asset(
                            'assets/restricted_parking_info.png',
                            width: screenWidth,
                            fit: BoxFit.cover,
                          ),

                          SizedBox(height: 24.0),

                          SizedBox(height: 12.0),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...['소화전 주변 5m : 소화전 주변은 과태료가 2배!', '교차로 모퉁이 5m : 교차로의 가장자리나 도로의 모퉁이는 주차를 피해주세요!', '버스정류소 10m : 버스가 정차하는 곳에는 주차하실 수 없어요!', '횡단보도 : 보행자가 길을 건너는 횡단보도 위에 주차하시면 위험해요!', '초등학교 어린이 보호구역 주출입구 및 도로 : 어린이들의 안전을 위해 주차 가능 시간대에 주의해주세요! 제한된 시간대에 주차 시 과태료 3배!'].map((text) => _featureRow(text, Colors.green)),
                            ],
                          ),
                        ],
                      )
                  ),
                ],
              ),
            ),
          )
        ]
      ),
    );
  }

  Widget _featureRow(String text, Color iconColor) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Baseline(
              baseline: 17.5,
              baselineType: TextBaseline.alphabetic,
              child: Icon(Icons.circle, color: iconColor, size: 10.0),
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: simpleText(
                text,
                20.0, FontWeight.bold, Colors.black, TextAlign.start
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
      ],
    );
  }
}