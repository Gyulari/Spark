import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:spark/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  bool _pwObscure = true;

  Future<void> _login() async {
    if(!_loginFormKey.currentState!.validate()) return;

    _loginFormKey.currentState!.save();

    setState(() {

    });

    try {
      final res = await SupabaseManager.client.auth.signInWithPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      if(res.user != null){
        if(!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log in completed: ${res.user!.email}'),),
        );

        await context.read<UserInfoState>().fetchUserInfo();

        if(!mounted) return;

        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if(e.message.contains('Invalid login')) {
        _showLoginErrorDialog('Check your email or password.\n\n{$e.message}');
      } else if(e.message.contains('not confirmed')) {
        _showLoginErrorDialog('Confirm your email first.\n\n{$e.message}');
      }
    } catch (e) {
      _showLoginErrorDialog('Error occurred.\n\n{$e}');
    } finally {
      setState(() {

      });
    }
  }

  void _showLoginErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Failed to log in'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                'assets/spark_logo.png',
                width: 256,
                height: 256,
                fit: BoxFit.fill,
              ),

              simpleText(
                'SPARK',
                36.0, FontWeight.bold, Colors.black, TextAlign.center
              ),

              SizedBox(height: 10.0),

              simpleText(
                '계정에 로그인하세요',
                20.0, FontWeight.normal, Colors.black, TextAlign.center,
              ),

              SizedBox(height: 40.0),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 420.0),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.0),
                      padding: EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(),
                      ),
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            inputLabel('이메일'),
                            TextFormField(
                              decoration: inputDeco('example@email.com'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || v.isEmpty)
                                ? '이메일을 입력하세요'
                                : null,
                              onSaved: (v) => _email = v!.trim(),
                              textInputAction: TextInputAction.next,
                            ),

                            SizedBox(height: 16.0),

                            inputLabel('비밀번호'),
                            TextFormField(
                              obscureText: _pwObscure,
                              decoration: inputDeco('Password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_pwObscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined
                                  ),
                                  onPressed: () => setState(() => _pwObscure = !_pwObscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                ? '비밀번호를 입력하세요'
                                : null,
                              onSaved: (v) => _password = v!.trim(),
                              textInputAction: TextInputAction.done,
                            ),

                            SizedBox(height: 24.0),

                            SizedBox(
                              width: double.infinity,
                              height: 48.0,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                onPressed: () {
                                  _login();
                                },
                                child: simpleText(
                                  '로그인',
                                  20.0, FontWeight.bold, Colors.white, TextAlign.start
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 16.0),

              simpleText(
                '아직 계정이 없으신가요?',
                16.0, FontWeight.bold, Colors.grey, TextAlign.center
              ),

              TextButton(
                onPressed: () {Navigator.pushNamed(context, '/login/signup');},
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        )
      )
    );
  }
}