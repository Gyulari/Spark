import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:spark/provider.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String userName = '김스파크';
  String userEmail = 'spark@example.com';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.blue[700],
            flexibleSpace: FlexibleSpaceBar(
              title: simpleText(
                '마이페이지',
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
                  _profileCard(),

                  SizedBox(height: 20.0),

                  _menuItem(
                    icon: Icons.history,
                    text: '예약 내역',
                    onTap: () {
                      context.read<NavState>().setSelectedIndex(3);
                    }
                  ),

                  _menuItem(
                    icon: Icons.info_outline,
                    text: '이용 안내',
                    onTap: () {

                    }
                  ),

                  _menuItem(
                    icon: Icons.support_agent,
                    text: '고객 지원',
                    onTap: () {},
                  ),

                  SizedBox(height: 10.0),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: ListTile(
                      title: Center(
                        child: simpleText(
                          '로그아웃',
                          20.0, FontWeight.bold, Colors.red, TextAlign.center
                        ),
                      ),
                      onTap: () {
                        // todo: Logout
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ]
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.blueAccent,
            child: simpleText(
              userName,
              12.0, FontWeight.bold, Colors.white, TextAlign.center
            ),
          ),

          SizedBox(height: 10.0),
          simpleText(
            userName,
            24.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 2.0),
          simpleText(
            userEmail,
            20.0, FontWeight.bold, Colors.black, TextAlign.center
          ),

          SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.green, size: 16.0),
              SizedBox(width: 4.0),
              simpleText(
                '인증 완료',
                16.0, FontWeight.bold, Colors.green, TextAlign.start
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  })
  {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: simpleText(
          text,
          14.0, FontWeight.normal, Colors.black, TextAlign.start
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
      ),
    );
  }
}