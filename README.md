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

dependencies:
  neworion_pdf_editor: ^0.0.1

Then run:
flutter pub get

📂 Usage
Here's a working example:




     
    Future<void> _editPDF() async {
     if (_pdfFile == null) return;
     setState(() => _isLoading = true);
    File? editedFile = await OPdf.openEditor(context, _pdfFile!);
    setState(() {
      _pdfFile = editedFile;
      _isLoading = false;
    });
    }
    
  


