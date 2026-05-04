import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';

class NotesSection extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const NotesSection({super.key, required this.value, required this.onChanged});

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(NotesSection old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: Tokens.base,
        borderRadius: BorderRadius.circular(Tokens.r2),
        border: Border.all(color: Tokens.borderSoft, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: null,
        minLines: 2,
        style: Type.body(size: 14, height: 1.55),
        cursorColor: Tokens.ink,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: 'anything to note. stays on this device.',
          hintStyle: Type.body(size: 14, color: Tokens.graphite2, height: 1.55),
        ),
      ),
    );
  }
}
