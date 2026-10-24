import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:weather/pages/chats/whatsapp_parser.dart';

const _waBackground = Color(0xFFECE5DD);
const _waHeader = Color(0xFF075E54);
const _waSentBubble = Color(0xFFDCF8C6);
const _waReceivedBubble = Colors.white;
const _waAccent = Color(0xFF25D366);

class WChatsPage extends StatefulWidget {
  const WChatsPage({super.key});

  @override
  State<WChatsPage> createState() => _WChatsPageState();
}

class _WChatsPageState extends State<WChatsPage> {
  WhatsAppChat? _chat;
  String? _myName;
  bool _loading = false;
  String? _error;
  bool _searchActive = false;
  String _searchQuery = '';
  List<int> _matchIndices = [];
  int _matchCursor = -1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<int, GlobalKey> _itemKeys = {};

  static const _selfNames = {'you', 'आप', 'tu', 'tú', 'você', 'voces'};

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _importChat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final path = file.path;
      final String raw;
      if (path != null) {
        raw = await _readFile(path);
      } else if (file.bytes != null) {
        raw = _decodeBytes(file.bytes!);
      } else {
        setState(() => _error = 'Could not read the selected file.');
        return;
      }
      final chat = WhatsAppParser.parse(raw, fileName: file.name);

      if (chat.messages.isEmpty) {
        setState(() => _error = 'No messages found in this export file.');
        return;
      }

      setState(() {
        _chat = chat;
        _clearSearch();
        _itemKeys.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        _promptMyNameIfNeeded();
      });
    } catch (e) {
      setState(() => _error = 'Failed to import chat: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String> _readFile(String path) async {
    return _decodeBytes(await File(path).readAsBytes());
  }

  String _decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _isGroupChat() {
    if (_chat == null) return false;
    final others = _chat!.messages
        .where((m) => !m.isSystemMessage && m.sender.isNotEmpty && !_isMyMessage(m))
        .map((m) => m.sender)
        .toSet();
    return others.length > 1;
  }

  void _clearSearch() {
    _searchActive = false;
    _searchQuery = '';
    _matchIndices = [];
    _matchCursor = -1;
    _searchController.clear();
  }

  void _toggleSearch() {
    setState(() {
      if (_searchActive) {
        _clearSearch();
      } else {
        _searchActive = true;
      }
    });
    if (_searchActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_chat == null) return;

    final items = _chatItems(_chat!.messages);
    final q = query.trim().toLowerCase();
    final matches = <int>[];

    if (q.isNotEmpty) {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is _ChatMessageItem &&
            item.message.content.toLowerCase().contains(q)) {
          matches.add(i);
        }
      }
    }

    setState(() {
      _searchQuery = query;
      _matchIndices = matches;
      _matchCursor = matches.isNotEmpty ? 0 : -1;
    });

    if (matches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMatch(0));
    }
  }

  void _goToNextMatch() {
    if (_matchIndices.isEmpty) return;
    final next = (_matchCursor + 1) % _matchIndices.length;
    setState(() => _matchCursor = next);
    _scrollToMatch(next);
  }

  void _goToPrevMatch() {
    if (_matchIndices.isEmpty) return;
    final prev =
        (_matchCursor - 1 + _matchIndices.length) % _matchIndices.length;
    setState(() => _matchCursor = prev);
    _scrollToMatch(prev);
  }

  void _scrollToMatch(int cursor) {
    if (cursor < 0 || cursor >= _matchIndices.length) return;

    final listIndex = _matchIndices[cursor];
    final key = _itemKeys[listIndex];
    final context = key?.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.25,
    );
  }

  bool _isMyMessage(WhatsAppMessage message) {
    final sender = message.sender.trim().toLowerCase();
    if (_selfNames.contains(sender)) return true;
    if (_myName != null && sender == _myName!.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  void _promptMyNameIfNeeded() {
    if (_chat == null || !mounted) return;
    if (_chat!.messages.any(_isMyMessage)) return;

    final senders = _chat!.messages
        .where((m) => !m.isSystemMessage && m.sender.isNotEmpty)
        .map((m) => m.sender)
        .toSet()
        .toList();

    if (senders.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Which one is you?',
                  style: _waTextStyle(
                    fontSize: 18,
                    weight: 700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick your name so your messages appear on the right.',
                  style: _waTextStyle(
                    fontSize: 14,
                    weight: 500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                ...senders.map(
                  (name) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name, style: _waTextStyle(weight: 600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      setState(() => _myName = name);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeMyName() async {
    if (_chat == null) return;

    final senders = _chat!.messages
        .where((m) => !m.isSystemMessage && m.sender.isNotEmpty)
        .map((m) => m.sender)
        .toSet()
        .toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your name in this chat',
                  style: _waTextStyle(fontSize: 18, weight: 700),
                ),
                const SizedBox(height: 16),
                ...senders.map(
                  (name) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _isMyMessage(WhatsAppMessage(sender: name, content: ''))
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _waAccent,
                    ),
                    title: Text(name, style: _waTextStyle(weight: 600)),
                    onTap: () => Navigator.pop(context, name),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) setState(() => _myName = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _waBackground,
      appBar: AppBar(
        backgroundColor: _waHeader,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _searchActive
            ? IconButton(
                tooltip: 'Close search',
                onPressed: _toggleSearch,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _goToNextMatch(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chat?.title ?? 'WhatsApp Chats',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_chat != null)
                    Text(
                      '${_chat!.messages.length} messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
        actions: [
          if (_searchActive) ...[
            if (_searchQuery.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    _matchIndices.isEmpty
                        ? '0/0'
                        : '${_matchCursor + 1}/${_matchIndices.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Previous match',
              onPressed: _matchIndices.isEmpty ? null : _goToPrevMatch,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'Next match',
              onPressed: _matchIndices.isEmpty ? null : _goToNextMatch,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
          if (_chat != null && !_searchActive)
            IconButton(
              tooltip: 'Search chat',
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          if (_chat != null && !_searchActive)
            IconButton(
              tooltip: 'Set your name',
              onPressed: _changeMyName,
              icon: const Icon(Icons.person_outline_rounded),
            ),
          if (!_searchActive)
            IconButton(
              tooltip: 'Import chat',
              onPressed: _loading ? null : _importChat,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: _waBackground,
          image: DecorationImage(
            image: _WaWallpaperPattern(),
            repeat: ImageRepeat.repeat,
            opacity: 0.35,
          ),
        ),
        child: _chat == null ? _buildEmptyState() : _buildChatView(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: _waHeader.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Import a WhatsApp chat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF303030),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Export a chat from WhatsApp as .txt, then import it here to view it like the real app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _importChat,
              style: FilledButton.styleFrom(
                backgroundColor: _waAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Choose .txt file'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    final items = _chatItems(_chat!.messages);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isActiveMatch = _matchCursor >= 0 &&
            _matchIndices.isNotEmpty &&
            _matchIndices[_matchCursor] == index;
        final isSearchMatch = _searchQuery.trim().isNotEmpty &&
            _matchIndices.contains(index);

        final key = _itemKeys.putIfAbsent(index, GlobalKey.new);
        final child = switch (item) {
          _ChatDateItem(:final date) => _DateDivider(date: date),
          _ChatSystemItem(:final text) => _SystemMessage(text: text),
          _ChatMessageItem(
            :final message,
            :final isSent,
            :final isFirstInGroup,
            :final isLastInGroup,
          ) =>
            _MessageBubble(
              message: message,
              isSent: isSent,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              showSender: _isGroupChat() && !isSent && isFirstInGroup,
              searchQuery: _searchQuery,
              isSearchMatch: isSearchMatch,
              isActiveMatch: isActiveMatch,
            ),
        };

        return KeyedSubtree(key: key, child: child);
      },
    );
  }

  List<_ChatListItem> _chatItems(List<WhatsAppMessage> messages) {
    final items = <_ChatListItem>[];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final date = message.dateTime;
      if (date != null) {
        final day = DateTime(date.year, date.month, date.day);
        if (lastDate == null || day != lastDate) {
          items.add(_ChatDateItem(date: day));
          lastDate = day;
        }
      }

      if (message.isSystemMessage || message.sender.isEmpty) {
        items.add(_ChatSystemItem(text: message.content));
        continue;
      }

      final isSent = _isMyMessage(message);
      final prev = i > 0 ? messages[i - 1] : null;
      final next = i < messages.length - 1 ? messages[i + 1] : null;

      final groupedWithPrev = prev != null &&
          !prev.isSystemMessage &&
          prev.sender.isNotEmpty &&
          _isMyMessage(prev) == isSent &&
          prev.sender == message.sender;

      final groupedWithNext = next != null &&
          !next.isSystemMessage &&
          next.sender.isNotEmpty &&
          _isMyMessage(next) == isSent &&
          next.sender == message.sender;

      items.add(
        _ChatMessageItem(
          message: message,
          isSent: isSent,
          isFirstInGroup: !groupedWithPrev,
          isLastInGroup: !groupedWithNext,
        ),
      );
    }

    return items;
  }
}

TextStyle _waTextStyle({
  double fontSize = 15,
  int weight = 500,
  Color color = const Color(0xFF111111),
}) {
  return TextStyle(
    fontFamily: 'outfit',
    fontSize: fontSize,
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
    height: 1.35,
  );
}

class _WaWallpaperPattern extends ImageProvider<_WaWallpaperPattern> {
  const _WaWallpaperPattern();

  @override
  Future<_WaWallpaperPattern> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(const _WaWallpaperPattern());
  }

  @override
  ImageStreamCompleter loadImage(
    _WaWallpaperPattern key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_load(decode));
  }

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    const size = 120.0;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFD9CCBC);

    for (var x = 0.0; x < size; x += 24) {
      for (var y = 0.0; y < size; y += 24) {
        canvas.drawCircle(Offset(x + 6, y + 6), 1.2, paint);
        canvas.drawCircle(Offset(x + 18, y + 18), 1.2, paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    return ImageInfo(image: image);
  }
}

sealed class _ChatListItem {}

class _ChatDateItem extends _ChatListItem {
  _ChatDateItem({required this.date});

  final DateTime date;
}

class _ChatSystemItem extends _ChatListItem {
  _ChatSystemItem({required this.text});

  final String text;
}

class _ChatMessageItem extends _ChatListItem {
  _ChatMessageItem({
    required this.message,
    required this.isSent,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  final WhatsAppMessage message;
  final bool isSent;
  final bool isFirstInGroup;
  final bool isLastInGroup;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD4E8D1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _formatDate(date),
            style: _waTextStyle(
              fontSize: 12.5,
              weight: 600,
              color: const Color(0xFF54656F),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3C4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _waTextStyle(
              fontSize: 12.5,
              weight: 500,
              color: const Color(0xFF54656F),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isSent,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.showSender,
    this.searchQuery = '',
    this.isSearchMatch = false,
    this.isActiveMatch = false,
  });

  final WhatsAppMessage message;
  final bool isSent;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showSender;
  final String searchQuery;
  final bool isSearchMatch;
  final bool isActiveMatch;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    final bubbleColor = isSent ? _waSentBubble : _waReceivedBubble;
    final radius = _bubbleRadius();

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 1,
        bottom: isLastInGroup ? 6 : 1,
      ),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: isSent ? Alignment.bottomRight : Alignment.bottomLeft,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(11, 7, 9, 6),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                  border: isActiveMatch
                      ? Border.all(color: const Color(0xFFFFC107), width: 2)
                      : isSearchMatch
                          ? Border.all(
                              color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                              width: 1,
                            )
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 1.5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _BubbleContent(
                  message: message,
                  isSent: isSent,
                  showSender: showSender,
                  searchQuery: searchQuery,
                ),
              ),
              if (isLastInGroup)
                Positioned(
                  bottom: 0,
                  right: isSent ? -4 : null,
                  left: isSent ? null : -4,
                  child: CustomPaint(
                    size: const Size(10, 12),
                    painter: _BubbleTailPainter(
                      color: bubbleColor,
                      isSent: isSent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _bubbleRadius() {
    const big = Radius.circular(10);
    const small = Radius.circular(4);
    const flat = Radius.circular(2);

    if (isSent) {
      return BorderRadius.only(
        topLeft: isFirstInGroup ? big : small,
        topRight: isFirstInGroup ? big : small,
        bottomLeft: big,
        bottomRight: isLastInGroup ? flat : small,
      );
    }

    return BorderRadius.only(
      topLeft: isFirstInGroup ? big : small,
      topRight: isFirstInGroup ? big : small,
      bottomLeft: isLastInGroup ? flat : small,
      bottomRight: big,
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.isSent});

  final Color color;
  final bool isSent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isSent) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSent != isSent;
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.isSent,
    required this.showSender,
    this.searchQuery = '',
  });

  final WhatsAppMessage message;
  final bool isSent;
  final bool showSender;
  final String searchQuery;

  static const _senderColors = [
    Color(0xFF06CF9C),
    Color(0xFF53BDEB),
    Color(0xFFE542A3),
    Color(0xFFA62C71),
    Color(0xFFF0B330),
    Color(0xFF7F66FF),
  ];

  Color _senderColor(String name) {
    final index = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
        _senderColors.length;
    return _senderColors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSender)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              message.sender,
              style: _waTextStyle(
                fontSize: 13.5,
                weight: 700,
                color: _senderColor(message.sender),
              ),
            ),
          ),
        Wrap(
          alignment: isSent ? WrapAlignment.end : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 2,
          children: [
            _HighlightedText(
              text: message.content,
              query: searchQuery,
              style: _waTextStyle(fontSize: 15.5, weight: 600),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(message.dateTime),
                  style: _waTextStyle(
                    fontSize: 11,
                    weight: 500,
                    color: const Color(0xFF667781),
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 15,
                    color: Color(0xFF53BDEB),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final meridiem = dateTime.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $meridiem';
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    var start = 0;

    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: style.copyWith(
            backgroundColor: const Color(0xFFFFF176),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + q.length;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
