import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:spark/route_import.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(appKey: 'd048fb7ea16988dc1a7928b0e450f4f7');

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SupabaseManager.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavState()),
        ChangeNotifierProvider(create: (_) => FocusLotState()),
        ChangeNotifierProvider(create: (_) => UserInfoState()),
      ],
      child: const Spark(),
    ),
  );
}

class Spark extends StatelessWidget {
  const Spark({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spark',

      routes: {
        '/': (_) => InitialScreen(),
        '/login': (_) => LoginScreen(),
        '/login/signup': (_) => SignupScreen(),
        '/home': (_) => HomeScreen(),
      },
      initialRoute: '/',

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,

            children: [
              // Logo Image
              Image.asset(
                'assets/spark_logo.png',
                width: 250,
                height: 250,
                fit: BoxFit.fill,
              ),

              simpleText(
                'SPARK',
                36, FontWeight.bold, Colors.black, TextAlign.center),

              SizedBox(height: 10),

              simpleText(
                '당신의 주차를 더 스마트하게\nSmart-PARK',
                20, FontWeight.bold, Colors.black, TextAlign.center),

              SizedBox(height: 20),

              simpleText(
                'SPARK로 주차를 더 스마트하게 이용하세요.',
                24, FontWeight.bold, Colors.black, TextAlign.center),

              SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(0),
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  debugPrint('Move to LoginScreen');
                  Navigator.pushNamed(context, '/login');
                },
                child: simpleText(
                  '로그인',
                  20, FontWeight.bold, Colors.white, TextAlign.start
                ),
              ),

              SizedBox(height: 20.0),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(0),
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: simpleText(
                  '테스트용 둘러보기',
                  20, FontWeight.bold, Colors.white, TextAlign.start
                ),
              ),

              SizedBox(height: 40),

              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.notification_add),
                  simpleText(
                    '모든 개인정보는 안전하게 암호화되어 관리됩니다',
                    15, FontWeight.normal, Colors.black, TextAlign.start
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}