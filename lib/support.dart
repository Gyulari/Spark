import 'package:spark/app_import.dart';
import 'package:spark/style.dart';
import 'package:intl/intl.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: simpleText(
            '고객 지원',
            24.0, FontWeight.bold, Colors.white, TextAlign.start
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('서비스 이용에 도움이 필요하신가요?'),
            SizedBox(height: 24.0),

            _guideCard(
              icon: Icons.call,
              title: '상담원 연결',
              backgroundColor: Colors.red[50]!,
              fontColor: Colors.red,
              description: '02-123-4567',
            ),

            SizedBox(height: 20.0),

            _guideCard(
              icon: Icons.web,
              title: 'Safe Ride 공식 사이트',
              backgroundColor: Colors.blue[50]!,
              fontColor: Colors.blue,
              description: 'spark.com/support',
            ),

            SizedBox(height: 36.0),

            sectionTitle('많이 물어보시는 질문 (FAQ)'),
            SizedBox(height: 24.0),

            _featureCard(
              icon: Icons.local_parking,
              title: '주차장 정보가 표시되지 않아요',
              backgroundColor: Colors.blue[50]!,
              fontColor: Colors.blue,
              descriptions: ['지도를 움직여 위치를 갱신해보세요', '네트워크 환경을 확인해보세요', '주차장이 없는 지역이 아닌지 확인해보세요'],
            ),

            SizedBox(height: 20.0),

            _featureCard(
              icon: Icons.attach_money,
              title: '결제에 문제가 생겼어요',
              backgroundColor: Colors.green[50]!,
              fontColor: Colors.green,
              descriptions: ['결제 수단을 다시 한 번 확인해보세요', '네트워크 연결을 확인해보세요'],
            ),

            SizedBox(height: 20.0),

            _featureCard(
              icon: Icons.person,
              title: '계정 이용에 문제가 생겼어요',
              backgroundColor: Colors.purple[50]!,
              fontColor: Colors.purple,
              descriptions: ['로그아웃 후 다시 로그인을 시도해보세요', '문제가 발생한 부분을 1대1 문의를 통해 문의해주세요'],
            ),

            SizedBox(height:16.0),
            Divider(thickness: 2.5, height: 10.0, color: Color(0xFFE0E0E0)),
            SizedBox(height:16.0),

            sectionTitle('1대1 문의'),
            SizedBox(height: 24.0),

            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3.0,
                    color: Colors.grey.withAlpha(25),
                  ),
                ],
              ),
              child: InquiryForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideCard({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color fontColor,
    required String description,
  })
  {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
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
              Icon(icon, color: fontColor, size: 24.0),
              SizedBox(width: 10.0),
              simpleText(
                  title,
                  20.0, FontWeight.bold, fontColor, TextAlign.start
              ),
            ],
          ),

          SizedBox(height: 8.0),

          simpleText(
              description,
              18.0, FontWeight.bold, Colors.black, TextAlign.start
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color fontColor,
    required List<String> descriptions,
  })
  {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
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
              Icon(icon, color: fontColor, size: 24.0),
              SizedBox(width: 10.0),
              simpleText(
                  title,
                  18.0, FontWeight.bold, fontColor, TextAlign.start
              ),
            ],
          ),

          SizedBox(height: 12.0),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...descriptions.map((text) => _featureRow(text, fontColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _featureRow(String text, Color iconColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: iconColor, size: 8.0),
            SizedBox(width: 8.0),
            simpleText(
                text,
                16.0, FontWeight.normal, Colors.black, TextAlign.start
            ),
          ],
        ),
        SizedBox(height: 4.0),
      ],
    );
  }
}

class InquiryForm extends StatefulWidget {
  const InquiryForm({super.key});

  @override
  State<InquiryForm> createState() => InquiryFormState();
}

class InquiryFormState extends State<InquiryForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? selectedCategory;
  DateTime? selectedDate;

  final categories = [
    '주차장 정보 표시',
    '예약 및 결제',
    '계정 관련 문의',
    '기타 문의',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            simpleText(
                '어떤 부분에서 도움이 필요하신가요?',
                16.0, FontWeight.bold, Colors.black, TextAlign.start
            ),
            SizedBox(height: 12.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),

            SizedBox(height: 30.0),

            simpleText(
                '제목',
                16.0, FontWeight.bold, Colors.black, TextAlign.start
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
            ),

            SizedBox(height: 30.0),

            simpleText(
                '문의 내용',
                16.0, FontWeight.bold, Colors.black, TextAlign.start
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '문의 내용을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
            ),

            SizedBox(height: 20.0),

            simpleText(
                '문의 일자',
                16.0, FontWeight.bold, Colors.black, TextAlign.start
            ),
            SizedBox(height: 12.0),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                );

                if(picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: simpleText(
                    selectedDate == null
                        ? '문의 날짜를 선택하세요'
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                    16.0, FontWeight.normal, Colors.black, TextAlign.start
                ),
              ),
            ),

            SizedBox(height: 30.0),

            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: submitInquiry,
                child: simpleText(
                    '문의 접수하기',
                    18.0, FontWeight.bold, Colors.white, TextAlign.center
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void submitInquiry() {
    if(selectedCategory == null ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 항목을 입력해주세요')),
      );
      return;
    }

    // TODO : 문의 내용 데이터베이스 전송

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('문의가 접수되었습니다')),
    );
  }
}