import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor_lite/neworion_pdf_edit_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OPdf {
  static Future<File?> openEditor(
    BuildContext context,
    File pdfFile, {
    bool draw = true,
    bool text = true,
    bool highlight = true,
    bool underline = true,
    bool image = true,
    bool page = true,
  }) async {
    File? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OPdfEditScreen(
              pdfFile: pdfFile,
              draw: draw,
              text: text,
              highlight: highlight,
              underline: underline,
              image: image,
              page: page,
            ),
      ),
    );
    return result;
  }

  static Future<File?> addTextToPdf(File pdfFile, String text) async {
    try {
      // Read the existing PDF
      final PdfDocument document = PdfDocument(
        inputBytes: await pdfFile.readAsBytes(),
      );

      // Ensure there's at least one page
      if (document.pages.count == 0) {
        document.pages.add();
      }

      final PdfPage page = document.pages[0];
      final PdfGraphics graphics = page.graphics;
      final PdfBrush brush = PdfSolidBrush(PdfColor(255, 0, 0)); // Red color
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        30,
        style: PdfFontStyle.bold,
      );

      // Add text annotation
      graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: const Rect.fromLTWH(50, 50, 400, 100),
      );

      // Save the modified PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Save to a new file
      final directory = await getApplicationDocumentsDirectory();
      final File newPdf = File('${directory.path}/edited.pdf');
      await newPdf.writeAsBytes(bytes);

      // Open the saved PDF
      // OpenFile.open(newPdf.path);

      return newPdf;
    } catch (e) {
      print("Error editing PDF: $e");
      return null;
    }
  }
}
