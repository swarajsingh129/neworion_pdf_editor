import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neworion_pdf_editor_lite/components/colorPicker.dart';
import 'package:neworion_pdf_editor_lite/components/text_editing_box.dart';
import 'package:neworion_pdf_editor_lite/controllers/annotation_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/drawing_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/highlight_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/image_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/save_pdf_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/text_box_controller.dart';
import 'package:neworion_pdf_editor_lite/controllers/underline_controller.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class OPdfEditScreen extends StatefulWidget {
  final File pdfFile;
  final bool draw;
  final bool text;
  final bool highlight;
  final bool underline;
  final bool image;
  final bool page;
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
  late final PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  int _selectedIndex = -1;
  int _currentPage = 1;
  int _totalPages = 1;
  List<Offset?> _points = [];
  bool _isPageLoaded = false;
  final DrawingController _drawingController = DrawingController();
  final HighlightController _highlightController = HighlightController();
  final UnderlineController _underlineController = UnderlineController();
  final TextBoxController _textBoxController = TextBoxController();
  final ImageController _imageController = ImageController();
  final SavePdfController _savePdfController = SavePdfController();
  Color _highlightColor = Colors.yellow;
  Color _underlineColor = Colors.green;
  DrawingMode selectedMode = DrawingMode.none;
  bool isTextSelected = false;
  bool _isSaving = false;
  bool revertView = false;
  late File pdfFile;

  @override
  void initState() {
    super.initState();
    pdfFile = widget.pdfFile;
    _pdfViewerController = PdfViewerController();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _pdfViewerController.previousPage();
      _points.clear(); // Clear drawing when page changes
      setState(() {});
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      _pdfViewerController.nextPage();
      _points.clear(); // Clear drawing when page changes
      setState(() {});
    }
  }

  void _selectAnnotationColor(bool isHighlight) async {
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

  selectColor() async {
    Color selectedColor = await showColorPicker(
      context,
      _drawingController.getCurrentColor,
    );
    _drawingController.setColor(selectedColor);
    setState(() {});
  }

  popWithResult(File? file) {
    Navigator.pop(context, file);
  }

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

  // ✅ Image compression function
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 800, // Resize to reduce size
    );
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Widget getAppBarContent() {
    switch (_selectedIndex) {
      case 0:
        return drawOption();
      case 1:
        return textOption();
      case 2:
        return highlightOption();
      case 3:
        return underlineOption();
      case 4:
        return imageOption();
      case 5:
        return editPage();
      default:
        return Container();
    }
  }

  Future<void> _resetAllChanges(BuildContext context) async {
    bool confirmReset = await _showResetConfirmation(context);
    if (confirmReset) {
      // ✅ Clear all changes
      _drawingController.clearAllPages();
      _imageController.clearAllPages();
      _textBoxController.clearAllPages();
      _highlightController.clearAllPages(_pdfViewerController);
      _underlineController.clearAllPages(_pdfViewerController);
      setState(() {});
    }
  }

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
        false;
  }

  addPageAt(int index) async {
    var val = await _savePdfController.addBlankPageAt(index, pdfFile);
    if (val != null) {
      pdfFile = val;
    }

    await _drawingController.adjustPages(index + 1, isAdd: true);
    await _textBoxController.adjustPages(index + 1, isAdd: true);
    await _imageController.adjustPages(index + 1, isAdd: true);
    await _highlightController.adjustPages(
      index + 1,
      _pdfViewerController,
      isAdd: true,
    );
    await _underlineController.adjustPages(
      index + 1,
      _pdfViewerController,
      isAdd: true,
    );
    _currentPage = 1;
    setState(() {});
  }

  removePageAt(int index) async {
    var val = await _savePdfController.removePage(index, pdfFile);
    if (val != null) {
      pdfFile = val;
    }
    await _drawingController.adjustPages(index, isAdd: false);
    await _textBoxController.adjustPages(index, isAdd: false);
    await _imageController.adjustPages(index, isAdd: false);
    await _highlightController.adjustPages(
      index,
      _pdfViewerController,
      isAdd: false,
    );
    await _underlineController.adjustPages(
      index,
      _pdfViewerController,
      isAdd: false,
    );
    _currentPage = 1;
    setState(() {});
  }

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
                // Header
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

                // Add Page Before
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
                    addPageAt(_currentPage - 1);
                  },
                ),

                // Add Page After
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
                    addPageAt(_currentPage);
                    // _addPage(_currentPage, addBefore: false);
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
            'Are you sure you want to remove Page no.$pageNumber?\n(this action can not be undo/reset)',
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
                removePageAt(_currentPage);
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
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      appBar:
          _selectedIndex != -1
              ? null
              : AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        _resetAllChanges(context);
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
                  TextButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isSaving = true;
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
                        _isSaving = false;
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
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                automaticallyImplyLeading: false,

                backgroundColor: Colors.black,
                centerTitle:
                    true, // Avoid centering when row has multiple elements
              ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SingleChildScrollView(
              reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 1.414,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        IgnorePointer(
                          ignoring:
                              _selectedIndex != -1 &&
                              _selectedIndex != 2 &&
                              _selectedIndex != 3,
                          child: Opacity(
                            opacity: _isSaving ? 0 : 1,
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
                                  if (details.selectedText != null) {
                                    isTextSelected = true;
                                  } else {
                                    isTextSelected = false;
                                  }
                                });
                              },
                              onDocumentLoaded: (details) {
                                setState(() {
                                  _totalPages = details.document.pages.count;
                                  _isPageLoaded =
                                      true; // Set page loaded to true
                                });
                                _highlightController.setPage(_currentPage);
                                _underlineController.setPage(_currentPage);
                              },
                              onPageChanged: (details) {
                                setState(() {
                                  _currentPage = details.newPageNumber;
                                  _isPageLoaded =
                                      false; // Reset until page fully loads
                                });
                                _drawingController.setPage(_currentPage);
                                _highlightController.setPage(_currentPage);
                                _underlineController.setPage(_currentPage);
                                Future.delayed(
                                  const Duration(milliseconds: 400),
                                  () {
                                    setState(() {
                                      _isPageLoaded =
                                          true; // Set after delay to allow rendering
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
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
                                  revertView = true; // Set to true when tapped
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
                                      revertView = false;
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
                                      revertView = false;
                                    });
                                  },
                                ); // Reset after tap
                              },
                              child: AnimatedContainer(
                                margin: EdgeInsets.all(8),
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color:
                                      revertView
                                          ? Colors.grey.shade700.withOpacity(
                                            0.5,
                                          ) // Active color
                                          : Colors.grey.withOpacity(
                                            0.5,
                                          ), // Inactive color
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
                                    SizedBox(
                                      width: 4,
                                    ), // Small spacing between text and icon
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
              ? null
              : BottomAppBar(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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

  Widget buildOptionRow({
    required dynamic controller,
    required VoidCallback onAdd,
    required IconData addIcon,
    required String label,
    Color centerBtnColor = Colors.transparent,
    PdfViewerController? pdfController, // <-- Pass pdfController if required
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          // top: BorderSide(color: Colors.grey[900]!),
          // bottom: BorderSide(color: Colors.grey[900]!),
        ),
      ),
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
                        controller.undo(
                          pdfController!,
                        ); // ✅ Correct for annotations
                      } else {
                        controller.undo(); // ✅ For other controllers
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
                        controller.redo(
                          pdfController!,
                        ); // ✅ Correct for annotations
                      } else {
                        controller.redo(); // ✅ For other controllers
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
                          controller.clear(
                            pdfController!,
                          ); // ✅ Correct for annotations
                        } else {
                          controller.clear(); // ✅ For other controllers
                        }

                        setState(() {});
                      }
                    }
                    : null,
            text: "Clear",
          ),

          // if (selectedMode == DrawingMode.highlight)
          //   IconButton(
          //     icon: Icon(
          //       Icons.color_lens_outlined,
          //       color: _highlightColor,

          //       size: 25,
          //     ),
          //     onPressed: () {
          //       _selectAnnotationColor(true);
          //     },
          //   ),
          // if (selectedMode == DrawingMode.underline)
          //   IconButton(
          //     icon: Icon(
          //       Icons.color_lens_outlined,
          //       color: _underlineColor,
          //       size: 30,
          //     ),
          //     onPressed: () {
          //       _selectAnnotationColor(false);
          //     },
          //   ),
        ],
      ),
    );
  }

  // ✅ Reusable Undo/Redo Button
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
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color centerBtnColor = Colors.transparent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: centerBtnColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 25),
        onPressed: onPressed,
      ),
    );
  }

  // ✅ Draw Option
  Widget drawOption() => buildOptionRow(
    controller: _drawingController,
    onAdd: () async {
      await selectColor();
    },
    addIcon: Icons.draw,
    label: "Add Drawing",
    centerBtnColor: _drawingController.getCurrentColor,
  );

  // ✅ Text Option
  Widget textOption() => buildOptionRow(
    controller: _textBoxController,
    onAdd: () async {
      var textBox = _textBoxController.addTextBox();
      if (textBox == null) return;
      Map<String, dynamic>? result = await showTextEditDialog(context, textBox);

      if (result != null) {
        setState(() {
          textBox.text = result["text"] as String;
          textBox.fontSize = result["fontSize"] as double;
          textBox.color = result["color"] as Color;
        });
      }
    },
    addIcon: Icons.text_fields,
    label: "Add Text",
  );

  // ✅ Highlight Option
  Widget highlightOption() => buildOptionRow(
    controller: _highlightController,
    onAdd: () {
      _annotateText(true);
    },
    addIcon: Icons.highlight,
    label: "Highlight",
    pdfController: _pdfViewerController, // ✅ Pass PdfViewerController
    centerBtnColor: isTextSelected ? Colors.amber : Colors.transparent,
  );

  // ✅ Underline Option with PdfViewerController
  Widget underlineOption() => buildOptionRow(
    controller: _underlineController,
    onAdd: () {
      _annotateText(false);
    },
    addIcon: Icons.format_underline,
    label: "Underline",
    pdfController: _pdfViewerController, // ✅ Pass PdfViewerController
    centerBtnColor: isTextSelected ? Colors.green : Colors.transparent,
  );

  // ✅ Image Option
  Widget imageOption() => buildOptionRow(
    controller: _imageController,
    onAdd: () async {
      await _addImage();
    },
    addIcon: Icons.add_photo_alternate_rounded,
    label: "Add Image",
  );

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
        // Previous Button
        // _buildActionButton(
        //   onPressed: () {
        //     _showAddPageOptions(context);
        //   },
        //   icon: Icons.add_circle_outline,
        //   label: "Add Page",
        // ),
        _buildUndoRedoButton(
          icon: Icons.add_circle_outline,
          enabled: true,
          onPressed: () {
            _showAddPageOptions(context);
          },
          text: "Add Page",
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
          icon: Icons.remove_circle_outline_outlined,
          enabled: true,
          onPressed: () {
            _showRemovePageConfirmation(context);
          },
          text: "Remove Page",
        ),
      ],
    ),
  );

  void _changeMode(DrawingMode mode) {
    setState(() {
      selectedMode = mode;
    });
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndex = -1;
            } else {
              _selectedIndex = index;
            }
            switch (index) {
              case 0:
                _changeMode(DrawingMode.drawing);
                break;
              case 1:
                _changeMode(DrawingMode.text);
                break;
              case 2:
                _changeMode(DrawingMode.highlight);
                break;
              case 3:
                _changeMode(DrawingMode.underline);
                break;
              case 4:
                _changeMode(DrawingMode.image);
                break;
              case 5:
                _changeMode(DrawingMode.edit);
              default:
                _changeMode(DrawingMode.none);
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
                color: isSelected ? Colors.white : Colors.grey,
                size: isSelected ? 26 : 20,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DrawingMode { none, drawing, text, image, highlight, underline, edit }

class DrawingCanvas extends StatefulWidget {
  final DrawingController drawingController;
  final TextBoxController textBoxController;
  final ImageController imageController;
  final int currentPage;
  final DrawingMode selectedMode;
  final VoidCallback callback;

  const DrawingCanvas({
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
    widget.drawingController.setPage(widget.currentPage);
    widget.textBoxController.setPage(widget.currentPage);
    widget.imageController.setPage(widget.currentPage);
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
    if (oldWidget.currentPage != widget.currentPage) {
      widget.drawingController.setPage(widget.currentPage);
      widget.textBoxController.setPage(widget.currentPage);
      widget.imageController.setPage(widget.currentPage);
    }
  }

  @override
  void dispose() {
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
          ...widget.imageController.getImageBoxes().map(_buildImageWidget),
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
          ...widget.textBoxController.getTextBoxes().map((textBox) {
            return Positioned(
              left: textBox.position.dx,
              top: textBox.position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (widget.selectedMode == DrawingMode.text) {
                    setState(() {
                      textBox.position += details.delta;
                    });
                  }
                },
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
                    // Cross Icon to Remove Text Box
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

  Positioned _buildImageWidget(ImageBox imageBox) {
    return Positioned(
      left: imageBox.position.dx,
      top: imageBox.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (widget.selectedMode == DrawingMode.image) {
            setState(() {
              // ✅ Drag to move image
              imageBox.position += details.delta;
            });
          }
        },
        child: Stack(
          children: [
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
            // ✅ Cross Icon to Remove Image
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
            // ✅ Resize Icon at Bottom Right
            if (widget.selectedMode == DrawingMode.image)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // ✅ Resize while maintaining aspect ratio
                      double aspectRatio = imageBox.width / imageBox.height;
                      double newWidth = imageBox.width + details.delta.dx;
                      double newHeight = newWidth / aspectRatio;

                      // ✅ Enforce minimum size to prevent disappearing
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
