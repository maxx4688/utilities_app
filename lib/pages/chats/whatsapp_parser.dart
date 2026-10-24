class WhatsAppMessage {
  WhatsAppMessage({
    required this.sender,
    required this.content,
    this.dateTime,
    this.isSystemMessage = false,
  });

  final String sender;
  final String content;
  final DateTime? dateTime;
  final bool isSystemMessage;

  bool get isSent => sender.toLowerCase() == 'you';
}

class WhatsAppChat {
  WhatsAppChat({
    required this.title,
    required this.messages,
  });

  final String title;
  final List<WhatsAppMessage> messages;
}

class WhatsAppParser {
  static final _messagePattern = RegExp(
    r'^(?:\[)?(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AP]M)?)\]?\s*[-–]?\s*(.+?):\s(.*)$',
    caseSensitive: false,
  );

  static WhatsAppChat parse(String raw, {String? fileName}) {
    final lines = raw.split('\n');
    final messages = <WhatsAppMessage>[];
    WhatsAppMessage? current;

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) continue;

      final match = _messagePattern.firstMatch(trimmed);
      if (match != null) {
        if (current != null) messages.add(current);
        current = WhatsAppMessage(
          sender: match.group(3)!.trim(),
          content: match.group(4)!.trim(),
          dateTime: _parseDateTime(match.group(1)!, match.group(2)!),
        );
        continue;
      }

      if (current != null) {
        current = WhatsAppMessage(
          sender: current.sender,
          content: '${current.content}\n$trimmed',
          dateTime: current.dateTime,
          isSystemMessage: current.isSystemMessage,
        );
      } else {
        messages.add(
          WhatsAppMessage(
            sender: '',
            content: trimmed,
            isSystemMessage: true,
          ),
        );
      }
    }

    if (current != null) messages.add(current);

    final title = _chatTitle(fileName, messages);
    return WhatsAppChat(title: title, messages: messages);
  }

  static String _chatTitle(String? fileName, List<WhatsAppMessage> messages) {
    if (fileName != null && fileName.isNotEmpty) {
      final cleaned = fileName
          .replaceAll(RegExp(r'\.txt$', caseSensitive: false), '')
          .replaceAll('WhatsApp Chat with ', '')
          .replaceAll('WhatsApp Chat - ', '')
          .trim();
      if (cleaned.isNotEmpty) return cleaned;
    }

    final senders = messages
        .where((m) => !m.isSystemMessage && m.sender.isNotEmpty)
        .map((m) => m.sender)
        .toSet()
        .where((s) => s.toLowerCase() != 'you')
        .toList();

    if (senders.length == 1) return senders.first;
    if (senders.isNotEmpty) return senders.join(', ');
    return 'WhatsApp Chat';
  }

  static DateTime? _parseDateTime(String datePart, String timePart) {
    final normalizedDate = datePart.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalizedDate.split('/');
    if (parts.length != 3) return null;

    int year;
    int month;
    int day;

    if (parts[0].length == 4) {
      year = int.tryParse(parts[0]) ?? 0;
      month = int.tryParse(parts[1]) ?? 0;
      day = int.tryParse(parts[2]) ?? 0;
    } else {
      day = int.tryParse(parts[0]) ?? 0;
      month = int.tryParse(parts[1]) ?? 0;
      year = int.tryParse(parts[2]) ?? 0;
      if (year < 100) year += 2000;
    }

    final timeMatch = RegExp(
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(timePart.trim());

    if (timeMatch == null) return null;

    var hour = int.tryParse(timeMatch.group(1)!) ?? 0;
    final minute = int.tryParse(timeMatch.group(2)!) ?? 0;
    final second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
    final meridiem = timeMatch.group(4)?.toUpperCase();

    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;

    return DateTime(year, month, day, hour, minute, second);
  }
}
