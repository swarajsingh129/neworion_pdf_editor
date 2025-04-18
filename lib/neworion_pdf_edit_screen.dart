// ignore_for_file: unused_element, deprecated_member_use, unnecessary_null_comparison

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neworion_pdf_editor/components/color_picker.dart';
import 'package:neworion_pdf_editor/components/text_editing_box.dart';
import 'package:neworion_pdf_editor/controllers/annotation_controller.dart';
import 'package:neworion_pdf_editor/controllers/drawing_controller.dart';
import 'package:neworion_pdf_editor/controllers/highlight_controller.dart';
import 'package:neworion_pdf_editor/controllers/image_controller.dart';
import 'package:neworion_pdf_editor/controllers/save_pdf_controller.dart';
import 'package:neworion_pdf_editor/controllers/text_box_controller.dart';
import 'package:neworion_pdf_editor/controllers/underline_controller.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A screen that allows users to edit a PDF, including annotating, drawing,
/// highlighting, adding text, and inserting images.
class OPdfEditScreen extends StatefulWidget {
  /// The PDF file to be edited.
  final File pdfFile;

  /// Whether the drawing functionality should be enabled.
  final bool draw;

  /// Whether the text annotation functionality should be enabled.
  final bool text;

  /// Whether the highlight annotation functionality should be enabled.
  final bool highlight;

  /// Whether the underline annotation functionality should be enabled.
  final bool underline;

  /// Whether the image addition functionality should be enabled.
  final bool image;

  /// Whether the page navigation functionality should be enabled.
  final bool page;

  /// Creates a new instance of [OPdfEditScreen].
  const OPdfEditScreen({
    super.key,
    required this.pdfFile,
    required this.draw,
    required this.text,
    required this.highlight,
    required this.underline,
    required this.image,
    required this.page,
  });

  @override
  State<OPdfEditScreen> createState() => _OPdfEditScreenState();
}

class _OPdfEditScreenState extends State<OPdfEditScreen> {
  /// Controller to handle the PDF viewer's actions.
  late final PdfViewerController _pdfViewerController;

  /// Global key used to access the PDF viewer's state.
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  /// The index of the currently selected annotation.
  int _selectedIndex = -1;

  /// The current page number of the PDF.
  int _currentPage = 1;

  /// The total number of pages in the PDF.
  int _totalPages = 1;

  /// The list of points used for drawing annotations.
  List<Offset?> _points = [];

  /// Flag to check if the PDF page has been loaded.
  bool _isPageLoaded = false;

  /// Controller to manage drawing annotations.
  final DrawingController _drawingController = DrawingController();

  /// Controller to manage highlight annotations.
  final HighlightController _highlightController = HighlightController();

  /// Controller to manage underline annotations.
  final UnderlineController _underlineController = UnderlineController();

  /// Controller to manage text box annotations.
  final TextBoxController _textBoxController = TextBoxController();

  /// Controller to manage image annotations.
  final ImageController _imageController = ImageController();

  /// Controller to handle saving the PDF.
  final SavePdfController _savePdfController = SavePdfController();

  /// The color used for highlighting annotations.
  Color _highlightColor = Colors.yellow;

  /// The color used for underlining annotations.
  Color _underlineColor = Colors.green;

  /// The current drawing mode selected by the user.
  DrawingMode selectedMode = DrawingMode.none;

  /// Flag to check if any text is selected for annotation.
  bool isTextSelected = false;

  /// Flag to check if the PDF is being saved.
  bool _isSaving = false;

  /// Flag to manage the view state (revert or not).
  bool revertView = false;

  /// The PDF file to be edited.
  late File pdfFile;

  @override
  void initState() {
    super.initState();
    pdfFile = widget.pdfFile;
    _pdfViewerController = PdfViewerController();
  }

  /// Navigates to the previous page in the PDF.
  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _pdfViewerController.previousPage();
      _points.clear(); // Clear drawing when page changes
      setState(() {});
    }
  }

  /// Navigates to the next page in the PDF.
  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      _pdfViewerController.nextPage();
      _points.clear(); // Clear drawing when page changes
      setState(() {});
    }
  }

  /// Opens a color picker to select a color for annotations (highlight/underline).
  Future<void> _selectAnnotationColor(bool isHighlight) async {
    Color selectedColor = await showColorPicker(
      context,
      isHighlight ? _highlightColor : _underlineColor,
    );

    if (selectedColor != null) {
      setState(() {
        if (isHighlight) {
          _highlightColor = selectedColor;
        } else {
          _underlineColor = selectedColor;
        }
      });
    }
  }

  /// Opens a color picker and sets the drawing color.
  selectColor() async {
    Color selectedColor = await showColorPicker(
      context,
      _drawingController.getCurrentColor,
    );
    _drawingController.setColor(selectedColor);
    setState(() {});
  }

  /// Pops the screen and returns the edited PDF file.
  popWithResult(File? file) {
    Navigator.pop(context, file);
  }

  /// Annotates the selected text with either highlight or underline.
  Future<void> _annotateText(bool isHighlight) async {
    List<PdfTextLine>? textLines =
        _pdfViewerKey.currentState?.getSelectedTextLines();
    if (textLines != null && textLines.isNotEmpty) {
      List<PdfTextMarkupAnnotation> pdfAnnotations = [];
      PdfColor selectedColor =
          isHighlight
              ? PdfColor(
                _highlightColor.red,
                _highlightColor.green,
                _highlightColor.blue,
              )
              : PdfColor(
                _underlineColor.red,
                _underlineColor.green,
                _underlineColor.blue,
              );

      for (var line in textLines) {
        PdfTextMarkupAnnotation annotation = PdfTextMarkupAnnotation(
          line.bounds,
          line.text,
          selectedColor,
          textMarkupAnnotationType:
              isHighlight
                  ? PdfTextMarkupAnnotationType.highlight
                  : PdfTextMarkupAnnotationType.underline,
        );
        pdfAnnotations.add(annotation);
      }

      // Create an annotation to display on the PDF viewer
      Annotation displayAnnotation;
      if (isHighlight) {
        displayAnnotation = HighlightAnnotation(
          textBoundsCollection: textLines,
        );
      } else {
        displayAnnotation = UnderlineAnnotation(
          textBoundsCollection: textLines,
        );
      }

      _pdfViewerController.addAnnotation(displayAnnotation);

      // Add the annotation to the appropriate controller (highlight or underline)
      isHighlight
          ? _highlightController.addAnnotation(
            AnnotationAction(
              displayAnnotation,
              isHighlight ? AnnotationType.highlight : AnnotationType.underline,
              pdfAnnotations,
              isAdd: true,
            ),
          )
          : _underlineController.addAnnotation(
            AnnotationAction(
              displayAnnotation,
              isHighlight ? AnnotationType.highlight : AnnotationType.underline,
              pdfAnnotations,
              isAdd: true,
            ),
          );
    }
  }

  /// Adds an image to the PDF by picking an image from the gallery.
  Future<void> _addImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      // Check if the image size is greater than 100 KB
      Uint8List compressedBytes = bytes;
      if (bytes.lengthInBytes > 200 * 1024) {
        compressedBytes = await _compressImage(bytes);
      }

      final codec = await ui.instantiateImageCodec(compressedBytes);
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      _imageController.addImage(image);
      setState(() {});
    }
  }

  // ✅ Image compression function to resize and reduce the size of images before adding to the PDF.
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Instantiate image codec with target width of 800px to resize the image
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 800, // Resize to reduce size
    );
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // Convert image to ByteData and then to Uint8List to return compressed image
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  // Get the content to display in the app bar based on the selected index.
  Widget getAppBarContent() {
    // Determine which option to display based on the selected index
    switch (_selectedIndex) {
      case 0:
        return drawOption(); // Drawing mode option
      case 1:
        return textOption(); // Text editing option
      case 2:
        return highlightOption(); // Highlighting option
      case 3:
        return underlineOption(); // Underlining option
      case 4:
        return imageOption(); // Image insertion option
      case 5:
        return editPage(); // Page editing option
      default:
        return Container(); // Default empty container if no option is selected
    }
  }

  // Reset all changes made to the document across all pages.
  Future<void> _resetAllChanges(BuildContext context) async {
    // Confirm if the user really wants to reset all changes
    bool confirmReset = await _showResetConfirmation(context);
    if (confirmReset) {
      // ✅ Clear all changes made by various controllers
      _drawingController.clearAllPages();
      _imageController.clearAllPages();
      _textBoxController.clearAllPages();
      _highlightController.clearAllPages(_pdfViewerController);
      _underlineController.clearAllPages(_pdfViewerController);
      setState(() {}); // Update the UI
    }
  }

  // Show confirmation dialog before resetting or clearing changes.
  Future<bool> _showResetConfirmation(
    BuildContext context, {
    bool reset = true,
    String modificationsType = "modification",
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  // Icon indicating action (reset or clear)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          reset
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reset ? Icons.refresh : Icons.replay,
                      color: reset ? Colors.red : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    reset ? 'Confirm Reset' : 'Confirm Clear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                reset
                    ? 'This will clear all modifications across all pages of the PDF. Do you want to proceed?'
                    : 'This will clear all $modificationsType on the current page of the PDF. Do you want to proceed?',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                // ❌ Cancel Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close, color: Colors.blue, size: 18),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                // ✅ Reset or Clear Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(
                    reset ? Icons.refresh : Icons.replay,
                    color: reset ? Colors.red : Colors.orange,
                    size: 18,
                  ),
                  label: Text(
                    reset ? 'Reset' : 'Clear',
                    style: TextStyle(color: reset ? Colors.red : Colors.orange),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog was dismissed
  }

  // Add a blank page at a specific index and adjust the page settings.
  addPageAt(int index) async {
    var val = await _savePdfController.addBlankPageAt(index, pdfFile);
    if (val != null) {
      pdfFile = val; // Update the file with the new page
    }

    // Adjust controllers to handle the new page across various features
    await _drawingController.adjustPages(index + 1, isAdd: true);
    await _textBoxController.adjustPages(index + 1, isAdd: true);
    await _imageController.adjustPages(index + 1, isAdd: true);
    await _highlightController.adjustPages(
      index + 1,
      _pdfViewerController,
      isAdd: true,
    );
    _underlineController.adjustPages(
      index + 1,
      _pdfViewerController,
      isAdd: true,
    );
    _currentPage = 1; // Set to the first page after adding a new one
    setState(() {}); // Update the UI
  }

  // Remove a page at the specified index and adjust the related settings.
  removePageAt(int index) async {
    var val = await _savePdfController.removePage(index, pdfFile);
    if (val != null) {
      pdfFile = val; // Update the file after removing the page
    }

    // Adjust controllers to handle the removed page across various features
    await _drawingController.adjustPages(index, isAdd: false);
    await _textBoxController.adjustPages(index, isAdd: false);
    await _imageController.adjustPages(index, isAdd: false);
    await _highlightController.adjustPages(
      index,
      _pdfViewerController,
      isAdd: false,
    );
    _underlineController.adjustPages(index, _pdfViewerController, isAdd: false);
    _currentPage = 1; // Reset to the first page after removing one
    setState(() {}); // Update the UI
  }

  // Show a dialog to allow the user to choose where to add a new page.
  void _showAddPageOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Add blank Page',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(Icons.edit_document, color: Colors.amber, size: 24),
                  ],
                ),
                const Divider(height: 20, thickness: 1),

                // Option to add a page before the current page
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.green),
                  ),
                  title: Text(
                    'Add at Page no. $_currentPage',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    addPageAt(
                      _currentPage - 1,
                    ); // Add page before the current page
                  },
                ),

                // Option to add a page after the current page
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.blue),
                  ),
                  title: Text(
                    'Add at Page no. ${_currentPage + 1}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    addPageAt(_currentPage); // Add page after the current page
                  },
                ),

                const SizedBox(height: 8),

                // Cancel Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show confirmation dialog before removing a page.
  Future _showRemovePageConfirmation(
    BuildContext context, {
    int pageNumber = 1,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              // Icon indicating removal
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Remove',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove Page no.$pageNumber?\n(this action can not be undone/reset)',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            // ❌ Cancel Button
            TextButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close, color: Colors.blue, size: 18),
              label: const Text('Cancel', style: TextStyle(color: Colors.blue)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            // ✅ Remove Button
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                removePageAt(_currentPage); // Proceed with page removal
              },
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevents UI from resizing when the keyboard appears
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black, // Background color for the page
      appBar:
          _selectedIndex != -1
              ? null // No AppBar if an option is selected
              : AppBar(
                // AppBar content for reset and save actions
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset Button
                    TextButton.icon(
                      onPressed: () async {
                        _resetAllChanges(context); // Reset all changes made
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white70,
                        size: 18,
                      ),
                      label: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Save Button
                  TextButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isSaving = true; // Set saving flag to true
                      });
                      await _savePdfController.saveDrawing(
                        pdfFile: pdfFile,
                        totalPages: _totalPages,
                        context: context,
                        drawingController: _drawingController,
                        imageController: _imageController,
                        textBoxController: _textBoxController,
                        highlightController: _highlightController,
                        underlineController: _underlineController,
                        refresh: () {
                          setState(() {});
                        },
                      );
                      setState(() {
                        _isSaving =
                            false; // Set saving flag back to false after saving
                      });
                    },
                    icon: const Icon(Icons.save, color: Colors.white, size: 20),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to previous screen
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                automaticallyImplyLeading:
                    false, // Disable default leading widget
                backgroundColor: Colors.black,
                centerTitle: true, // Center the title for consistency
              ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SingleChildScrollView(
              reverse: true, // Scroll view is reversed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 1.414,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        // PDF Viewer: Display PDF content with user interaction disabled in specific modes
                        IgnorePointer(
                          ignoring:
                              _selectedIndex != -1 &&
                              _selectedIndex != 2 &&
                              _selectedIndex != 3,
                          child: Opacity(
                            opacity: _isSaving ? 0 : 1, // Hide PDF when saving
                            child: SfPdfViewer.file(
                              key: _pdfViewerKey,
                              pdfFile,
                              controller: _pdfViewerController,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              scrollDirection: PdfScrollDirection.horizontal,
                              canShowScrollHead: false,
                              canShowPaginationDialog: false,
                              canShowTextSelectionMenu: false,
                              pageSpacing: 0,
                              maxZoomLevel: 1,
                              onTextSelectionChanged: (details) {
                                setState(() {
                                  // Check if text is selected
                                  isTextSelected = details.selectedText != null;
                                });
                              },
                              onDocumentLoaded: (details) {
                                setState(() {
                                  _totalPages =
                                      details
                                          .document
                                          .pages
                                          .count; // Update page count
                                  _isPageLoaded = true;
                                });
                                _highlightController.setPage(_currentPage);
                                _underlineController.setPage(_currentPage);
                              },
                              onPageChanged: (details) {
                                setState(() {
                                  _currentPage =
                                      details
                                          .newPageNumber; // Update current page number
                                  _isPageLoaded =
                                      false; // Reset page load state
                                });
                                _drawingController.setPage(_currentPage);
                                _highlightController.setPage(_currentPage);
                                _underlineController.setPage(_currentPage);
                                Future.delayed(
                                  const Duration(milliseconds: 400),
                                  () {
                                    setState(() {
                                      _isPageLoaded =
                                          true; // Allow page to fully load
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        // Drawing Canvas: Handle user input (drawing, text, etc.) on the canvas
                        Positioned.fill(
                          child: Opacity(
                            opacity: !_isPageLoaded || revertView ? 0 : 1,
                            child: IgnorePointer(
                              ignoring: _selectedIndex == -1,
                              child: DrawingCanvas(
                                drawingController: _drawingController,
                                textBoxController: _textBoxController,
                                imageController: _imageController,
                                currentPage: _currentPage,
                                selectedMode: selectedMode,
                                callback: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                        // Toggle visibility button: Hide or show content based on user interaction
                        if (_drawingController.hasContent() ||
                            _textBoxController.hasContent() ||
                            _imageController.hasContent() ||
                            _highlightController.hasContent() ||
                            _underlineController.hasContent())
                          Positioned(
                            right: 15,
                            bottom: 15,
                            child: GestureDetector(
                              onTapDown: (_) {
                                _underlineController.hide(_pdfViewerController);
                                _highlightController.hide(_pdfViewerController);
                                setState(() {
                                  revertView = true; // Toggle visibility flag
                                });
                              },
                              onTapCancel: () {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    _underlineController.unhide(
                                      _pdfViewerController,
                                    );
                                    _highlightController.unhide(
                                      _pdfViewerController,
                                    );
                                    setState(() {
                                      revertView =
                                          false; // Reset visibility flag
                                    });
                                  },
                                );
                              },
                              onTapUp: (_) {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    _underlineController.unhide(
                                      _pdfViewerController,
                                    );
                                    _highlightController.unhide(
                                      _pdfViewerController,
                                    );
                                    setState(() {
                                      revertView =
                                          false; // Reset visibility flag
                                    });
                                  },
                                );
                              },
                              child: AnimatedContainer(
                                margin: EdgeInsets.all(8),
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color:
                                      revertView
                                          ? Colors.grey.shade700.withOpacity(
                                            0.5,
                                          )
                                          : Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color:
                                        revertView
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade900,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  revertView
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color:
                                      revertView
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade900,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        // Saving Indicator: Show a loading spinner when saving
                        if (_isSaving)
                          Positioned.fill(
                            child: Opacity(
                              opacity: _isSaving ? 1 : 0,
                              child: Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Page navigation controls
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              'Page $_currentPage of $_totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Button
                            Opacity(
                              opacity: _currentPage > 1 ? 1.0 : 0.5,
                              child: TextButton(
                                onPressed:
                                    _currentPage > 1 ? _goToPreviousPage : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Previous',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Next Button
                            Opacity(
                              opacity: _currentPage < _totalPages ? 1.0 : 0.5,
                              child: InkWell(
                                onTap:
                                    _currentPage < _totalPages
                                        ? _goToNextPage
                                        : null,
                                child: Row(
                                  children: const [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            getAppBarContent(),
          ],
        ),
      ),
      bottomNavigationBar:
          _selectedIndex != -1
              ? null // Bottom navigation bar is hidden when an option is selected
              : BottomAppBar(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Show bottom navigation items conditionally
                    if (widget.draw) _buildBottomNavItem(Icons.edit, "Draw", 0),
                    if (widget.text)
                      _buildBottomNavItem(Icons.text_fields, "Text", 1),
                    if (widget.highlight)
                      _buildBottomNavItem(Icons.highlight, "Highlight", 2),
                    if (widget.underline)
                      _buildBottomNavItem(
                        Icons.format_underline,
                        "Underline",
                        3,
                      ),
                    if (widget.image)
                      _buildBottomNavItem(Icons.image_outlined, "Image", 4),
                    if (widget.page)
                      _buildBottomNavItem(Icons.edit_document, "Page", 5),
                  ],
                ),
              ),
    );
  }

  // Helper function to build option row for undo, redo, add, etc.
  Widget buildOptionRow({
    required dynamic controller,
    required VoidCallback onAdd,
    required IconData addIcon,
    required String label,
    Color centerBtnColor = Colors.transparent,
    PdfViewerController? pdfController,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
      decoration: BoxDecoration(color: Colors.black, border: Border()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildUndoRedoButton(
            icon: Icons.undo,
            enabled: controller.hasContent(),
            onPressed:
                controller.hasContent()
                    ? () {
                      if (controller is HighlightController ||
                          controller is UnderlineController) {
                        controller.undo(pdfController!); // Undo for annotations
                      } else {
                        controller.undo(); // Undo for other controllers
                      }
                      setState(() {});
                    }
                    : null,
            text: "Undo",
          ),
          _buildUndoRedoButton(
            icon: Icons.redo,
            enabled: controller.hasContent(isRedo: true),
            onPressed:
                controller.hasContent(isRedo: true)
                    ? () {
                      if (controller is HighlightController ||
                          controller is UnderlineController) {
                        controller.redo(pdfController!); // Redo for annotations
                      } else {
                        controller.redo(); // Redo for other controllers
                      }
                      setState(() {});
                    }
                    : null,
            text: "Redo",
          ),
          _buildActionButton(
            onPressed: onAdd,
            icon: addIcon,
            label: label,
            centerBtnColor: centerBtnColor,
          ),
          _buildUndoRedoButton(
            icon: Icons.check,
            enabled: true,
            onPressed: () {
              setState(() {
                _selectedIndex = -1;
                _changeMode(DrawingMode.none);
              });
            },
            text: "Done",
          ),
          _buildUndoRedoButton(
            icon: Icons.replay,
            enabled: controller.hasClearContent(),
            onPressed:
                controller.hasClearContent()
                    ? () async {
                      if (await _showResetConfirmation(
                        context,
                        reset: false,
                        modificationsType: selectedMode.name,
                      )) {
                        if (controller is HighlightController ||
                            controller is UnderlineController) {
                          controller.clear(pdfController!); // Clear annotations
                        } else {
                          controller.clear(); // Clear other controllers
                        }

                        setState(() {});
                      }
                    }
                    : null,
            text: "Clear",
          ),
        ],
      ),
    );
  }

  // Reusable Undo/Redo Button widget
  Widget _buildUndoRedoButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onPressed,
    String text = '',
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? Colors.white : Colors.grey[700]),

            Text(
              text,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey[700],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reusable Action Button (Add Drawing, Text, Highlight, etc.)
  /// A reusable button widget used for adding drawing, text, highlight, etc.
  Widget _buildActionButton({
    required VoidCallback onPressed, // Action when button is pressed
    required IconData icon, // Icon to display on button
    required String label, // Label text for the button
    Color centerBtnColor =
        Colors
            .transparent, // Color for the button's center, default is transparent
  }) {
    return Container(
      decoration: BoxDecoration(
        color: centerBtnColor, // Sets the color of the button's center
        borderRadius: BorderRadius.circular(20), // Rounded corners
        border: Border.all(color: Colors.white), // White border around button
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 25,
        ), // Icon with white color and size
        onPressed: onPressed, // Action to perform when button is pressed
      ),
    );
  }

  // ✅ Draw Option
  /// Option to add drawing on the PDF.
  Widget drawOption() => buildOptionRow(
    controller: _drawingController,
    onAdd: () async {
      await selectColor(); // Select the color for drawing
    },
    addIcon: Icons.draw, // Icon for drawing option
    label: "Add Drawing", // Label for the option
    centerBtnColor:
        _drawingController.getCurrentColor, // Current color for the drawing
  );

  // ✅ Text Option
  /// Option to add text to the PDF.
  Widget textOption() => buildOptionRow(
    controller: _textBoxController,
    onAdd: () async {
      var textBox = _textBoxController.addTextBox(); // Add a new text box
      if (textBox == null) return; // If no text box is added, return
      Map<String, dynamic>? result = await showTextEditDialog(
        context,
        textBox,
      ); // Show text editing dialog

      if (result != null) {
        // If a result is returned, update the text box properties
        setState(() {
          textBox.text = result["text"] as String;
          textBox.fontSize = result["fontSize"] as double;
          textBox.color = result["color"] as Color;
        });
      }
    },
    addIcon: Icons.text_fields, // Icon for text option
    label: "Add Text", // Label for the option
  );

  // ✅ Highlight Option
  /// Option to highlight text in the PDF.
  Widget highlightOption() => buildOptionRow(
    controller: _highlightController,
    onAdd: () {
      _annotateText(true); // Highlight text
    },
    addIcon: Icons.highlight, // Icon for highlight option
    label: "Highlight", // Label for the option
    pdfController:
        _pdfViewerController, // Pass PdfViewerController for handling PDF
    centerBtnColor:
        isTextSelected
            ? Colors.amber
            : Colors.transparent, // Change color when text is selected
  );

  // ✅ Underline Option with PdfViewerController
  /// Option to underline text in the PDF.
  Widget underlineOption() => buildOptionRow(
    controller: _underlineController,
    onAdd: () {
      _annotateText(false); // Underline text
    },
    addIcon: Icons.format_underline, // Icon for underline option
    label: "Underline", // Label for the option
    pdfController:
        _pdfViewerController, // Pass PdfViewerController for handling PDF
    centerBtnColor:
        isTextSelected
            ? Colors.green
            : Colors.transparent, // Change color when text is selected
  );

  // ✅ Image Option
  /// Option to add an image to the PDF.
  Widget imageOption() => buildOptionRow(
    controller: _imageController,
    onAdd: () async {
      await _addImage(); // Trigger image addition
    },
    addIcon: Icons.add_photo_alternate_rounded, // Icon for image option
    label: "Add Image", // Label for the option
  );

  // ✅ Edit Page Option
  /// Option to edit the page (Add, Done, or Remove Page).
  Widget editPage() => Container(
    padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border(
        top: BorderSide(color: Colors.grey[900]!),
        bottom: BorderSide(color: Colors.grey[900]!),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous Button (hidden by default)
        _buildUndoRedoButton(
          icon: Icons.add_circle_outline, // Icon for add page button
          enabled: true, // Button is enabled
          onPressed: () {
            _showAddPageOptions(context); // Show options to add a new page
          },
          text: "Add Page", // Text for the button
        ),
        _buildUndoRedoButton(
          icon: Icons.check, // Icon for done button
          enabled: true, // Button is enabled
          onPressed: () {
            setState(() {
              _selectedIndex = -1; // Reset selected index
              _changeMode(DrawingMode.none); // Reset to no drawing mode
            });
          },
          text: "Done", // Text for the button
        ),
        _buildUndoRedoButton(
          icon:
              Icons
                  .remove_circle_outline_outlined, // Icon for remove page button
          enabled: true, // Button is enabled
          onPressed: () {
            _showRemovePageConfirmation(
              context,
            ); // Show confirmation for page removal
          },
          text: "Remove Page", // Text for the button
        ),
      ],
    ),
  );

  // Helper function to change drawing mode
  void _changeMode(DrawingMode mode) {
    setState(() {
      selectedMode = mode; // Change the drawing mode
    });
  }

  // Bottom Navigation Item
  /// Creates a navigation item for the bottom navigation bar.
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final bool isSelected =
        _selectedIndex == index; // Check if the item is selected

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndex = -1; // Deselect if already selected
            } else {
              _selectedIndex = index; // Select the current item
            }
            switch (index) {
              case 0:
                _changeMode(DrawingMode.drawing); // Set mode to drawing
                break;
              case 1:
                _changeMode(DrawingMode.text); // Set mode to text
                break;
              case 2:
                _changeMode(DrawingMode.highlight); // Set mode to highlight
                break;
              case 3:
                _changeMode(DrawingMode.underline); // Set mode to underline
                break;
              case 4:
                _changeMode(DrawingMode.image); // Set mode to image
                break;
              case 5:
                _changeMode(DrawingMode.edit); // Set mode to edit
                break;
              default:
                _changeMode(DrawingMode.none); // Set mode to none
                break;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? Colors.white
                        : Colors.grey, // Change color when selected
                size: isSelected ? 26 : 20, // Change size when selected
              ),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : Colors.grey, // Change text color when selected
                  fontSize: 10,
                  fontWeight:
                      isSelected
                          ? FontWeight.bold
                          : FontWeight
                              .normal, // Change text weight when selected
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enum representing the different drawing modes for the canvas
enum DrawingMode { none, drawing, text, image, highlight, underline, edit }

/// A StatefulWidget that provides a canvas for drawing, text editing, and image manipulation
class DrawingCanvas extends StatefulWidget {
  final DrawingController
  drawingController; // Controller to handle drawing actions
  final TextBoxController
  textBoxController; // Controller to handle text box actions
  final ImageController imageController; // Controller to handle image actions
  final int currentPage; // The current page being edited
  final DrawingMode
  selectedMode; // The mode currently selected (e.g., drawing, text)
  final VoidCallback callback; // Callback for when an action is completed

  const DrawingCanvas({
    super.key,
    required this.drawingController,
    required this.textBoxController,
    required this.imageController,
    required this.currentPage,
    required this.selectedMode,
    required this.callback,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  void initState() {
    super.initState();
    // Set up controllers for the current page
    widget.drawingController.setPage(widget.currentPage);
    widget.textBoxController.setPage(widget.currentPage);
    widget.imageController.setPage(widget.currentPage);

    // Add listeners to update the canvas when changes occur in any controller
    widget.drawingController.addListener(() {
      setState(() {});
    });
    widget.textBoxController.addListener(() {
      setState(() {});
    });
    widget.imageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the page changes, reset controllers for the new page
    if (oldWidget.currentPage != widget.currentPage) {
      widget.drawingController.setPage(widget.currentPage);
      widget.textBoxController.setPage(widget.currentPage);
      widget.imageController.setPage(widget.currentPage);
    }
  }

  @override
  void dispose() {
    // Remove listeners when the widget is disposed
    widget.drawingController.removeListener(() {
      setState(() {});
    });
    widget.textBoxController.removeListener(() {
      setState(() {});
    });
    widget.imageController.removeListener(() {
      setState(() {});
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Gesture handling for drawing, text, and image interactions
      onPanStart: (details) {
        if (widget.selectedMode == DrawingMode.drawing) {
          widget.drawingController.startDraw(details.localPosition);
        }
      },
      onPanUpdate: (details) {
        if (widget.selectedMode == DrawingMode.drawing) {
          widget.drawingController.drawing(details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (widget.selectedMode == DrawingMode.drawing) {
          widget.callback();
        }
      },
      onTapUp: (details) {
        if (widget.selectedMode == DrawingMode.text) {
          widget.textBoxController.selectTextBox(details.localPosition);
        }
      },
      child: Stack(
        children: [
          // Display image boxes on the canvas
          ...widget.imageController.getImageBoxes().map(_buildImageWidget),
          // Drawing layer with ability to paint dynamically
          IgnorePointer(
            ignoring: widget.selectedMode != DrawingMode.drawing,
            child: ClipRect(
              child: RepaintBoundary(
                key: widget.drawingController.painterKey,
                child: CustomPaint(
                  painter: DrawingPainter(controller: widget.drawingController),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Display and manage text boxes
          ...widget.textBoxController.getTextBoxes().map((textBox) {
            return Positioned(
              left: textBox.position.dx,
              top: textBox.position.dy,
              child: GestureDetector(
                // Allow text box dragging
                onPanUpdate: (details) {
                  if (widget.selectedMode == DrawingMode.text) {
                    setState(() {
                      textBox.position += details.delta;
                    });
                  }
                },
                // Allow text box editing
                onTap: () async {
                  if (widget.selectedMode != DrawingMode.text) {
                    return;
                  }
                  Map<String, dynamic>? result = await showTextEditDialog(
                    context,
                    textBox,
                  );

                  if (result != null) {
                    setState(() {
                      textBox.text = result["text"] as String;
                      textBox.fontSize = result["fontSize"] as double;
                      textBox.color = result["color"] as Color;
                    });
                  }
                },
                child: Stack(
                  children: [
                    // Display the text box content with custom styles
                    Container(
                      width: textBox.width,
                      height: textBox.height,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Center(
                        child: Text(
                          textBox.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: textBox.fontSize,
                            color: textBox.color ?? Colors.black,
                            fontFamily: 'Helvetica',
                          ),
                        ),
                      ),
                    ),
                    // Cross Icon to remove text box
                    if (widget.selectedMode == DrawingMode.text)
                      Positioned(
                        right: -0, // Positioned correctly to avoid overlap
                        top: -0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              widget.textBoxController.removeTextBox(textBox);
                            });
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 10,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Resize Icon at Bottom Right
                    if (widget.selectedMode == DrawingMode.text)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              textBox.width += details.delta.dx;
                              textBox.height += details.delta.dy;
                            }); // Prevent negative width/height
                            textBox.width = textBox.width.clamp(
                              20,
                              double.infinity,
                            );
                            textBox.height = textBox.height.clamp(
                              20,
                              double.infinity,
                            );
                          },
                          child: const Icon(
                            Icons.open_with,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds and positions an image widget on the canvas
  Positioned _buildImageWidget(ImageBox imageBox) {
    return Positioned(
      left: imageBox.position.dx,
      top: imageBox.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (widget.selectedMode == DrawingMode.image) {
            setState(() {
              // Drag to move the image
              imageBox.position += details.delta;
            });
          }
        },
        child: Stack(
          children: [
            // Transform image (rotate, scale)
            Transform(
              transform:
                  Matrix4.identity()
                    ..translate(imageBox.width / 2, imageBox.height / 2)
                    ..rotateZ(imageBox.rotation)
                    ..translate(-imageBox.width / 2, -imageBox.height / 2),
              alignment: Alignment.center,
              child: Container(
                width: imageBox.width + 2,
                height: imageBox.height + 2,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: CustomPaint(painter: ImagePainter(imageBox)),
              ),
            ),
            // Cross Icon to remove image
            if (widget.selectedMode == DrawingMode.image)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.imageController.removeImage(imageBox);
                    });
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 10,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            // Resize Icon at Bottom Right
            if (widget.selectedMode == DrawingMode.image)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Resize while maintaining aspect ratio
                      double aspectRatio = imageBox.width / imageBox.height;
                      double newWidth = imageBox.width + details.delta.dx;
                      double newHeight = newWidth / aspectRatio;

                      // Prevent shrinking the image below a minimum size
                      if (newWidth > 20 && newHeight > 20) {
                        imageBox.width = newWidth;
                        imageBox.height = newHeight;
                      }
                    });
                  },
                  child: const Icon(
                    Icons.open_with,
                    size: 18,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
