import 'package:flutter/material.dart';

class InternalNoteDialog extends StatefulWidget {
  final String? initialNote;
  final String title;

  const InternalNoteDialog({super.key, this.initialNote, required this.title});

  @override
  _InternalNoteDialogState createState() => _InternalNoteDialogState();
}

class _InternalNoteDialogState extends State<InternalNoteDialog> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        maxLines: 5,
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'أدخل الملاحظة الداخلية هنا',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_noteController.text),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

void showInternalNoteDialog(
  BuildContext context, {
  String? initialNote,
  required Function(String) onSave,
  required String title,
}) {
  showDialog(
    context: context,
    builder: (context) => InternalNoteDialog(
      initialNote: initialNote,
      title: title,
    ),
  ).then((value) {
    if (value != null && value is String) {
      onSave(value);
    }
  });
}
