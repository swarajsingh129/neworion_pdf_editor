import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A controller that manages drawing, text boxes, undo/redo, and page-specific actions
/// for a multi-page PDF or canvas editor.
class DrawingController extends ChangeNotifier {
  final Map<int, List<TextBox>> _textBoxes = {};
  final Map<int, List<PaintContent>> _history = {};
  final Map<int, List<PaintContent>> _undoStack = {};
  
  /// Global key for accessing the repaint boundary for image capturing.
  final GlobalKey painterKey = GlobalKey();
  
  int _currentPage = 0;

  /// Returns the list of drawing history for the current page.
  List<PaintContent> get getHistory => _history[_currentPage] ?? [];

  /// Returns the list of text boxes for the current page.
  List<TextBox> getTextBoxes() => _textBoxes[_currentPage] ?? [];

  /// Returns all text boxes mapped by page index.
  Map<int, List<TextBox>> getAllTextBoxes() => _textBoxes;

  /// Current selected drawing color.
  Color _currentColor = Colors.red;

  /// Returns the current selected color.
  Color get getCurrentColor => _currentColor;

  /// Sets a new drawing color.
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  /// Sets the active page and initializes data structures if needed.
  void setPage(int page) {
    _currentPage = page;
    _textBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  /// Starts a new drawing stroke at the given [startPoint].
  void startDraw(Offset startPoint) {
    _history.putIfAbsent(_currentPage, () => []);
    _undoStack.putIfAbsent(_currentPage, () => []);
    _history[_currentPage]!.add(SimpleLine(startPoint, _currentColor));
    notifyListeners();
  }

  /// Updates the current drawing stroke with a new point.
  void drawing(Offset nowPaint) {
    if (_history[_currentPage]?.isNotEmpty == true) {
      _history[_currentPage]!.last.update(nowPaint);
      notifyListeners();
    }
  }

  /// Ends the current drawing action.
  void endDraw() {
    notifyListeners();
  }

  /// Undoes the last drawing or action.
  void undo() {
    if (_history[_currentPage]?.isNotEmpty == true) {
      var lastAction = _history[_currentPage]!.removeLast();
      _undoStack[_currentPage]!.add(lastAction);
      notifyListeners();
    }
  }

  /// Redoes the last undone action.
  void redo() {
    if (_undoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _undoStack[_currentPage]!.removeLast();
      _history[_currentPage]!.add(lastAction);
      notifyListeners();
    }
  }

  /// Checks if there is content to undo or redo.
  bool hasContent({bool isRedo = false}) {
    if (isRedo) {
      return _undoStack[_currentPage]?.isNotEmpty == true;
    }
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true;
  }

  /// Checks if there is any content to clear (drawings, text, undo stack).
  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  /// Clears all drawings, text boxes, and undo stack for the current page.
  void clear() {
    _history[_currentPage] = [];
    _undoStack[_currentPage] = [];
    _textBoxes[_currentPage] = [];
    notifyListeners();
  }

  /// Clears all drawings, text boxes, and undo stacks for all pages.
  void clearAllPages() {
    _history.clear();
    _undoStack.clear();
    _textBoxes.clear();
    setPage(0);
    notifyListeners();
  }

  /// Captures the current canvas as an image and returns it as [ByteData].
  Future<ByteData?> getImageData(int page) async {
    try {
      final RenderRepaintBoundary boundary =
          painterKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint();
      canvas.drawImage(originalImage, Offset.zero, paint);

      final ui.Image finalImage = await recorder.endRecording().toImage(
        originalImage.width,
        originalImage.height,
      );

      return await finalImage.toByteData(format: ui.ImageByteFormat.png);
    } catch (e) {
      debugPrint('Error capturing or flipping image: $e');
      return null;
    }
  }

  /// Returns all drawings across all pages.
  Map<int, List<PaintContent>> getAllDrawings() {
    return _history;
  }

  /// Adjusts page indexes after adding or removing a page.
  ///
  /// If [isAdd] is true, pages are shifted upwards. Otherwise, they are shifted downwards.
  Future<void> adjustPages(int pageIndex, {bool isAdd = true}) async {
    final newHistory = <int, List<PaintContent>>{};
    final newUndoStack = <int, List<PaintContent>>{};
    final newTextBoxes = <int, List<TextBox>>{};

    _history.forEach((key, value) {
      if (isAdd) {
        newHistory[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newHistory[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _undoStack.forEach((key, value) {
      if (isAdd) {
        newUndoStack[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newUndoStack[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _textBoxes.forEach((key, value) {
      if (isAdd) {
        newTextBoxes[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newTextBoxes[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);
    _textBoxes
      ..clear()
      ..addAll(newTextBoxes);

    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners();
  }
}

/// A simple freehand line composed of points and a color.
class SimpleLine extends PaintContent {
  /// List of points that form the line.
  List<Offset> points = [];

  /// Color of the line.
  Color color;

  /// Creates a new [SimpleLine] with a starting point and color.
  SimpleLine(Offset startPoint, this.color) {
    points.add(startPoint);
  }

  @override
  void update(Offset newPoint) {
    points.add(newPoint);
  }

  @override
  void paintOnCanvas(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
}

/// Abstract class representing any drawable content on the canvas.
abstract class PaintContent {
  /// Paints the content on the given [canvas].
  void paintOnCanvas(Canvas canvas);

  /// Updates the content with a new point.
  void update(Offset newPoint);
}

/// Custom painter that paints all the drawings from [DrawingController].
class DrawingPainter extends CustomPainter {
  /// Controller that manages the drawing content.
  final DrawingController controller;

  /// Creates a new [DrawingPainter] with the given [controller].
  DrawingPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    for (var content in controller.getHistory) {
      content.paintOnCanvas(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
