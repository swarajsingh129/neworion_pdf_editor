import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor_lite/components/colorPicker.dart';
import 'package:neworion_pdf_editor_lite/neworion_pdf_edit_screen.dart' as OPdf;

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TexteditingboxContent extends StatefulWidget {
  const TexteditingboxContent({super.key, required this.textBox});
  final OPdf.TextBox textBox;
  @override
  State<TexteditingboxContent> createState() => _TexteditingboxContentState();
}

class _TexteditingboxContentState extends State<TexteditingboxContent> {
  late TextEditingController controller;
  late double fontSize;
  late Color selectedColor;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.textBox.text);
    fontSize = widget.textBox.fontSize;
    selectedColor = widget.textBox.color ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Text"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Text"),
          ),
          Row(
            children: [
              const Text("Font Size:"),
              Slider(
                value: fontSize,
                min: 8,
                max: 32,
                divisions: 24,
                label: fontSize.toInt().toString(),
                onChanged: (newValue) {
                  fontSize = newValue;
                  setState(() {});
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Text Color:"),
              IconButton(
                icon: Icon(Icons.color_lens, color: selectedColor),
                onPressed: () async {
                  Color? pickedColor = await showColorPicker(
                    context,
                    selectedColor,
                  );
                  if (pickedColor != null) {
                    selectedColor = pickedColor;
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(context, {
                "text": controller.text,
                "fontSize": fontSize,
                "color": selectedColor,
              }),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
