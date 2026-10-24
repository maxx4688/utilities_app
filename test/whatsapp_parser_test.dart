import 'package:flutter_test/flutter_test.dart';
import 'package:weather/pages/chats/whatsapp_parser.dart';

void main() {
  test('parses bracketed WhatsApp export format', () {
    const raw = '''
[15/07/2026, 10:30:15 AM] John: Hello there
[15/07/2026, 10:31:00 AM] You: Hi John!
''';

    final chat = WhatsAppParser.parse(raw, fileName: 'WhatsApp Chat with John.txt');

    expect(chat.title, 'John');
    expect(chat.messages.length, 2);
    expect(chat.messages.first.sender, 'John');
    expect(chat.messages.first.content, 'Hello there');
    expect(chat.messages.last.isSent, isTrue);
  });

  test('parses dash-separated WhatsApp export format', () {
    const raw = '''
15/07/2026, 10:30 AM - Jane: First line
second line of message
15/07/2026, 10:31 AM - You: Reply
''';

    final chat = WhatsAppParser.parse(raw);

    expect(chat.messages.length, 2);
    expect(chat.messages.first.content, 'First line\nsecond line of message');
    expect(chat.messages.last.isSent, isTrue);
  });
}
