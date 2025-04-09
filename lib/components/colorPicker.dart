import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<Color> showColorPicker(BuildContext context, Color currentColor) async {
  Color pickedColor = currentColor;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select'),
          ),
        ],
      );
    },
  );
  return pickedColor;
}
