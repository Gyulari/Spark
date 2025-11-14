import 'package:spark/app_import.dart';

class BottomNavBar extends StatelessWidget {
  final int curIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.curIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: curIndex,
      onTap: onTap,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '내 정보',
        ),
      ],
    );
  }
}