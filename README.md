📄 neworion_pdf_editor

A powerful Flutter PDF editor that enables you to draw, highlight, underline, add text or images, and save changes back to the PDF — all with an intuitive UI. Built on top of Syncfusion's PDF Viewer and PDF libraries, this editor is ideal for creating note-taking, document review, or annotation apps.

<p align="center">
  <a href="https://buymeacoffee.com/swarajsingo" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="250" >
  </a>
</p>

✨ Platform support: Android and iOS only.

<p align="center">
  <img src="https://github.com/user-attachments/assets/0f7342b7-b90f-4504-bffc-e39f2585503b" width="150"/>
  <img src="https://github.com/user-attachments/assets/90b29f30-538e-4947-ad9c-ddcf9cab6502" width="150"/>
  <img src="https://github.com/user-attachments/assets/b4d5a129-057f-405c-91d3-d3145922e795" width="150"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/d754cb0e-8ffb-4dba-bbd6-9e8628b2dbda" width="150"/>
  <img src="https://github.com/user-attachments/assets/ef8414ec-b806-4d51-bec3-4723f736eff8" width="150"/>
  <img src="https://github.com/user-attachments/assets/c40a579f-b7f8-42f7-90a3-8fcc1676560c" width="150"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/b55340a2-0751-4eed-b099-25786c574b0a" width="150"/>
  <img src="https://github.com/user-attachments/assets/62177294-da12-4f1d-a65f-19d82693cfac" width="150"/>
</p>

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

## Author

👨‍💻 **Swaraj Singh**  
📧 linkedIn: https://www.linkedin.com/in/swarajsingh129/ 
🌐 TopMate: https://topmate.io/swaraj_singh_129



## Support

<p align="center">
  <a href="https://buymeacoffee.com/swarajsingo" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="250" >
  </a>
</p>

If you find this package useful, consider supporting me on [Buy Me a Coffee](https://buymeacoffee.com/swarajsingo)!
