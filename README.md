📄 neworion_pdf_editor
A powerful Flutter PDF editor that enables you to draw, highlight, underline, add text or images, and save changes back to the PDF — all with an intuitive UI. Built on top of Syncfusion's PDF Viewer and PDF libraries, this editor is ideal for creating note-taking, document review, or annotation apps.

✨ Platform support: Android and iOS only.

✨ Features
✅ Add freehand drawings to PDFs

✅ Insert customizable text boxes

✅ Highlight and underline text with ease

✅ Insert and resize images on PDF pages

✅ Interactive dragging, resizing, and rotating of elements

✅ Page-wise undo/redo history for all changes

✅ Save your edits back to a new PDF file

✅ Seamless integration with syncfusion_flutter_pdfviewer

🚀 Getting Started
📦 Installation
Add this to your pubspec.yaml:

yaml
Copy
Edit
dependencies:
  neworion_pdf_editor: ^0.0.1
Then run:

bash
Copy
Edit
flutter pub get
📂 Usage
Here's a complete working example:

dart
Copy
Edit
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:neworion_pdf_editor/neworion_pdf_editor.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor Demo',
      home: const PDFEditorScreen(),
    );
  }
}

class PDFEditorScreen extends StatefulWidget {
  const PDFEditorScreen({super.key});
  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  File? _pdfFile;
  bool _isLoading = false;

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _editPDF() async {
    if (_pdfFile == null) return;

    setState(() => _isLoading = true);
    File? editedFile = await OPdf.openEditor(context, _pdfFile!);
    setState(() {
      _pdfFile = editedFile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Editor')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _pickPDF, child: const Text('Pick PDF')),
          ElevatedButton(onPressed: _editPDF, child: const Text('Edit PDF')),
          if (_isLoading) const CircularProgressIndicator(),
          if (_pdfFile != null && !_isLoading)
            Expanded(child: SfPdfViewer.file(_pdfFile!)),
        ],
      ),
    );
  }
}
🛠️ Supported Actions
Action	Description
Draw	Freehand drawing with color options
Text	Add resizable, editable text boxes
Annotate	Highlight or underline text
Image	Add and resize/rotate images
Undo/Redo	Page-based undo/redo for all actions
Save	Save annotated version of the PDF
