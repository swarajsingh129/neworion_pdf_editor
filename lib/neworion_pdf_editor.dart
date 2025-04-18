import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor/neworion_pdf_edit_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// Class to handle PDF editing actions
class OPdf {
  // Open the PDF editor screen with various options for editing
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
    // Navigate to the PDF editor screen and wait for the result
    File? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OPdfEditScreen(
              pdfFile: pdfFile, // The PDF file to edit
              draw: draw, // Option to allow drawing
              text: text, // Option to allow text editing
              highlight: highlight, // Option to allow highlighting
              underline: underline, // Option to allow underlining
              image: image, // Option to allow image editing
              page: page, // Option to allow page navigation
            ),
      ),
    );
    // Return the edited PDF file
    return result;
  }

  // Add text to an existing PDF
  static Future<File?> addTextToPdf(File pdfFile, String text) async {
    try {
      // Read the existing PDF into a PdfDocument object
      final PdfDocument document = PdfDocument(
        inputBytes: await pdfFile.readAsBytes(),
      );

      // Ensure that the document has at least one page, adding one if necessary
      if (document.pages.count == 0) {
        document.pages.add();
      }

      // Get the first page from the document
      final PdfPage page = document.pages[0];
      final PdfGraphics graphics = page.graphics;

      // Create a red color brush and a bold Helvetica font for the text
      final PdfBrush brush = PdfSolidBrush(PdfColor(255, 0, 0)); // Red color
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        30,
        style: PdfFontStyle.bold,
      );

      // Draw the provided text on the first page at a specified location
      graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: const Rect.fromLTWH(50, 50, 400, 100),
      );

      // Save the modified document as a byte array
      final List<int> bytes = await document.save();
      document.dispose();

      // Get the application's document directory and create a new file path for the edited PDF
      final directory = await getApplicationDocumentsDirectory();
      final File newPdf = File('${directory.path}/edited.pdf');

      // Write the modified PDF to the new file
      await newPdf.writeAsBytes(bytes);

      // Open the saved PDF (optional, currently commented out)
      // OpenFile.open(newPdf.path);

      return newPdf; // Return the new file
    } catch (e) {
      // If an error occurs, print it and return null
      log("Error editing PDF: $e");
      return null;
    }
  }
}
