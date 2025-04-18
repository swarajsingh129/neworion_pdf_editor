// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor/controllers/annotation_controller.dart';
import 'package:neworion_pdf_editor/controllers/drawing_controller.dart';
import 'package:neworion_pdf_editor/controllers/highlight_controller.dart';
import 'package:neworion_pdf_editor/controllers/image_controller.dart';
import 'package:neworion_pdf_editor/controllers/text_box_controller.dart';
import 'package:neworion_pdf_editor/controllers/underline_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A controller responsible for handling all save and manipulation
/// operations on a PDF, including drawing, annotations, text boxes, 
/// images, adding/removing pages, and saving the final document.
class SavePdfController extends ChangeNotifier {
  /// Tracks whether a save operation is currently in progress.
  bool isSaving = false;

  /// Saves the current edits (drawings, images, annotations, and text boxes)
  /// to a new PDF file.
  ///
  /// [pdfFile] - the original PDF file,
  /// [totalPages] - number of pages in the document,
  /// [context] - BuildContext for getting MediaQuery,
  /// [drawingController], [imageController], [textBoxController], 
  /// [highlightController], [underlineController] - various controllers 
  /// managing different edit types,
  /// [refresh] - callback to refresh UI if needed.
  Future<void> saveDrawing({
    required pdfFile,
    required int totalPages,
    required BuildContext context,
    required DrawingController drawingController,
    required ImageController imageController,
    required TextBoxController textBoxController,
    required HighlightController highlightController,
    required UnderlineController underlineController,
    required Function refresh,
  }) async {
    if (isSaving) {
      return;
    }
    try {
      isSaving = true; // Start loading

      final pdfDoc = PdfDocument(inputBytes: await pdfFile.readAsBytes());

      for (int i = 0; i < totalPages; i++) {
        // Set the current page in the drawing controller
        drawingController.setPage(i + 1);
        PdfPage page = pdfDoc.pages[i];

        // Allow time for page switch to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // --- Add highlight annotations ---
        for (AnnotationAction action
            in highlightController.getHighlightHistory[i + 1] ?? []) {
          if (action.isAdd) {
            for (int j = 0; j < action.pdfAnnotation.length; j++) {
              if (i < pdfDoc.pages.count) {
                pdfDoc.pages[i].annotations.add(action.pdfAnnotation[j]);
              }
            }
          }
        }

        // --- Add underline annotations ---
        for (AnnotationAction action
            in underlineController.getUnderlineHistory[i + 1] ?? []) {
          if (action.isAdd) {
            for (int j = 0; j < action.pdfAnnotation.length; j++) {
              if (i < pdfDoc.pages.count) {
                pdfDoc.pages[i].annotations.add(action.pdfAnnotation[j]);
              }
            }
          }
        }

        // --- Add images onto PDF page ---
        for (var imageBox in imageController.getAllImageBoxes()[i + 1] ?? []) {
          final imgData = await _convertImageToUint8List(imageBox.image);
          final PdfImage pdfImage = PdfBitmap(imgData);

          final double scaleFactorX =
              page.getClientSize().width / MediaQuery.of(context).size.width;
          final double scaleFactorY =
              page.getClientSize().height /
              (MediaQuery.of(context).size.width * 1.414);

          double scaledX = imageBox.position.dx * scaleFactorX;
          double scaledY = imageBox.position.dy * scaleFactorY;
          double scaledWidth = imageBox.width * scaleFactorX;
          double scaledHeight = imageBox.height * scaleFactorY;

          // Save the current graphics state before transformations
          page.graphics.save();

          // Apply rotation and translation
          page.graphics.translateTransform(
            scaledX + scaledWidth / 2,
            scaledY + scaledHeight / 2,
          );
          page.graphics.rotateTransform(imageBox.rotation * (180 / pi));

          // Draw the image
          page.graphics.drawImage(
            pdfImage,
            Rect.fromLTWH(
              (-scaledWidth / 2) + 14,
              (-scaledHeight / 2) + 14,
              scaledWidth,
              scaledHeight,
            ),
          );

          // Restore the graphics state
          page.graphics.restore();
        }

        // --- Add freehand drawing on the PDF page ---
        ByteData? imageData = await drawingController.getImageData(i + 1);
        if (imageData != null) {
          final PdfImage image = PdfBitmap(imageData.buffer.asUint8List());

          final double pageWidth = page.getClientSize().width;
          final double pageHeight = page.getClientSize().height;

          page.graphics.drawImage(
            image,
            Rect.fromLTWH(0, 0, pageWidth, pageHeight),
          );
        }

        // --- Add text boxes on the PDF page ---
        for (TextBox textBox
            in textBoxController.getAllTextBoxes()[i + 1] ?? []) {
          final double scaleFactorX =
              page.getClientSize().width / MediaQuery.of(context).size.width;
          final double scaleFactorY =
              page.getClientSize().height /
              (MediaQuery.of(context).size.width * 1.414);

          double scaledX = textBox.position.dx * scaleFactorX;
          double scaledY = textBox.position.dy * scaleFactorY;
          double scaledWidth = textBox.width * scaleFactorX;
          double scaledHeight = textBox.height * scaleFactorY;

          page.graphics.drawString(
            textBox.text,
            PdfStandardFont(PdfFontFamily.helvetica, textBox.fontSize),
            brush: PdfSolidBrush(
              PdfColor(
                textBox.color?.red ?? 0,
                textBox.color?.green ?? 0,
                textBox.color?.blue ?? 0,
              ),
            ),
            bounds: Rect.fromLTWH(
              scaledX + 10, // Padding for better text visibility
              scaledY + 10,
              scaledWidth,
              scaledHeight,
            ),
            format: PdfStringFormat(
              alignment: PdfTextAlignment.center,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }
      }

      // --- Save the modified PDF file ---
      final output = await getTemporaryDirectory();
      final String originalName = pdfFile.path.split('/').last.split('.').first;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String savedPath = '${output.path}/${originalName}_$timestamp.pdf';
      final file = File(savedPath);

      await file.writeAsBytes(await pdfDoc.save());
      pdfDoc.dispose();

      // Pop with result file
      Navigator.pop(context, file);

      // Optionally, you can open the saved file
      // OpenFile.open(savedPath);
    } catch (e) {
      debugPrint('Error while saving drawing and text: $e');
    } finally {
      isSaving = false; // End loading
    }
  }

  /// Converts a [ui.Image] into a [Uint8List] for PDF embedding.
  Future<Uint8List> _convertImageToUint8List(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  /// Adds a blank page at the given [pageIndex] in the PDF.
  ///
  /// Returns the updated file if successful, or null otherwise.
  Future<File?> addBlankPageAt(int pageIndex, File pdfFile) async {
    final pdfDoc = PdfDocument(inputBytes: await pdfFile.readAsBytes());
    if (pageIndex < 0 || pageIndex > pdfDoc.pages.count) {
      debugPrint('Invalid page index: $pageIndex');
      return null;
    }

    final Size pageSize = Size(
      pdfDoc.pages[0].getClientSize().width,
      pdfDoc.pages[0].getClientSize().height,
    );

    pdfDoc.pages.insert(pageIndex, pageSize);

    return await saveFile(pdfDoc: pdfDoc, addTimestap: false, pdfFile: pdfFile);
  }

  /// Removes the page at [currentPage] (1-based index) from the PDF.
  ///
  /// Returns the updated file if successful, or null otherwise.
  Future<File?> removePage(int currentPage, File pdfFile) async {
    final PdfDocument pdfDoc = PdfDocument(
      inputBytes: await pdfFile.readAsBytes(),
    );

    if (pdfDoc.pages.count > 1) {
      pdfDoc.pages.removeAt(currentPage - 1);

      return await saveFile(pdfDoc: pdfDoc, pdfFile: pdfFile);
    }
    return null;
  }

  /// Saves the modified [pdfDoc] either with or without a timestamp.
  ///
  /// [addTimestap] decides whether to append a timestamp to the filename.
  Future<File?> saveFile({
    bool addTimestap = false,
    required File pdfFile,
    required PdfDocument pdfDoc,
  }) async {
    final output = await getTemporaryDirectory();
    final String originalName = pdfFile.path.split('/').last.split('.').first;

    String savedPath = "";
    if (addTimestap) {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      savedPath = '${output.path}/${originalName}_$timestamp.pdf';
    } else {
      savedPath = '${output.path}/$originalName.pdf';
    }

    final file = File(savedPath);

    await file.writeAsBytes(await pdfDoc.save());
    return file;
  }
}
