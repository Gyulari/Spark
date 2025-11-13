import 'package:spark/app_import.dart';

Widget simpleText(String text, double size, FontWeight weight, Color color, TextAlign align) {
  return Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
    ),
    textAlign: align,
  );
}

Widget inputLabel(String text) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 12.0),
    child: simpleText(
        text,
        16, FontWeight.normal, Colors.black, TextAlign.start
    ),
  );
}

InputDecoration inputDeco(String hint) {
  return InputDecoration(
      hintText: hint,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.blue, width: 1.8),
      )
  );
}

Widget divider() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.0),
    child: Divider(
      height: 1.0,
      thickness: 1.0,
      color: Color(0xFFF0F3F7),
    ),
  );
}


Widget sectionTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: simpleText(
        title,
        24.0, FontWeight.bold, Colors.black, TextAlign.start
    ),
  );
}