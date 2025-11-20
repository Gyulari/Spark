import 'package:spark/app_import.dart';
import 'package:spark/map.dart';
import 'package:spark/parking_info.dart';
import 'package:spark/favorite.dart';
import 'package:spark/reserve_history.dart';
import 'package:spark/my_page.dart';
import 'package:spark/bottom_nav_bar.dart';
import 'package:spark/nav_stat.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  // 로그인 위젯 State 객체
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    MapView(),
    ParkingInfo(),
    Favorite(),
    ReserveHistory(),
    MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavState(),
      child: Scaffold(
        body: Consumer<NavState>(
          builder: (context, navState, child) {
            return _screens[navState.selectedIndex];
          },
        ),
        bottomNavigationBar: Consumer<NavState>(
          builder: (context, navState, child) {
            return BottomNavBar(
                curIndex: navState.selectedIndex,
                onTap: (index) {
                  navState.setSelectedIndex(index);
                }
            );
          },
        ),
      ),
    );
  }
}