import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingController extends ChangeNotifier {
  final Map<int, List<TextBox>> _textBoxes = {};
  final Map<int, List<PaintContent>> _history = {};
  final Map<int, List<PaintContent>> _undoStack = {};
  final GlobalKey painterKey = GlobalKey();
  int _currentPage = 0;
  List<PaintContent> get getHistory => _history[_currentPage] ?? [];
  List<TextBox> getTextBoxes() => _textBoxes[_currentPage] ?? [];
  Map<int, List<TextBox>> getAllTextBoxes() => _textBoxes;
  // ✅ New: Default drawing color
  Color _currentColor = Colors.red;
  Color get getCurrentColor => _currentColor;
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    _textBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  void startDraw(Offset startPoint) {
    _history.putIfAbsent(_currentPage, () => []);
    _undoStack.putIfAbsent(_currentPage, () => []);

    // ✅ Pass selected color to the SimpleLine
    _history[_currentPage]!.add(SimpleLine(startPoint, _currentColor));
    notifyListeners();
  }

  void drawing(Offset nowPaint) {
    if (_history[_currentPage]?.isNotEmpty == true) {
      _history[_currentPage]!.last.update(nowPaint);
      notifyListeners();
    }
  }

  void endDraw() {
    notifyListeners();
  }

  void undo() {
    if (_history[_currentPage]?.isNotEmpty == true) {
      var lastAction = _history[_currentPage]!.removeLast();
      _undoStack[_currentPage]!.add(lastAction);

      if (lastAction is SimpleLine) {
        // Handle drawing undo
        notifyListeners();
      }
      //  else if (lastAction is TextBoxAction) {
      //   // Handle text box undo
      //   if (lastAction.isAdd) {
      //     _textBoxes[_currentPage]?.remove(lastAction.textBox);
      //   } else {
      //     _textBoxes[_currentPage]?.add(lastAction.textBox);
      //   }
      // }
      notifyListeners();
    }
  }

  void redo() {
    if (_undoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _undoStack[_currentPage]!.removeLast();
      _history[_currentPage]!.add(lastAction);

      if (lastAction is SimpleLine) {
        // Redo drawing
        notifyListeners();
      }
      // else if (lastAction is TextBoxAction) {
      //   // Redo text box
      //   if (lastAction.isAdd) {
      //     _textBoxes[_currentPage]?.add(lastAction.textBox);
      //   } else {
      //     _textBoxes[_currentPage]?.remove(lastAction.textBox);
      //   }
      // }
      notifyListeners();
    }
  }

  bool hasContent({bool isRedo = false}) {
    if (isRedo) {
      return _undoStack[_currentPage]?.isNotEmpty == true;
    }
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true;
  }

  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  void clear() {
    _history[_currentPage] = [];
    _undoStack[_currentPage] = [];
    _textBoxes[_currentPage] = [];
    notifyListeners();
  }

  clearAllPages() {
    _history.clear();
    _undoStack.clear();
    _textBoxes.clear();
    setPage(0);
    notifyListeners();
  }

  Future<ByteData?> getImageData(int page) async {
    try {
      final RenderRepaintBoundary boundary =
          painterKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;

      // Increase pixel ratio to 3.0 or higher for higher resolution
      final ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      // Create a recorder to capture the flipped image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      //  final double height = originalImage.height.toDouble();
      //       // Flip vertically: Translate and scale
      //       if (Platform.isAndroid) {
      //         canvas.translate(0, height);
      //         canvas.scale(1, -1);
      //       } // Only invert Y-axis

      // Draw the original image onto the flipped canvas
      final Paint paint = Paint();
      canvas.drawImage(originalImage, Offset.zero, paint);

      // End recording and create a new image
      final ui.Image flippedImage = await recorder.endRecording().toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert flipped image to byte data (PNG format)
      return await flippedImage.toByteData(format: ui.ImageByteFormat.png);
    } catch (e) {
      debugPrint('Error capturing or flipping image: $e');
      return null;
    }
  }

  Map<int, List<PaintContent>> getAllDrawings() {
    return _history;
  }

   adjustPages(int pageIndex, {bool isAdd = true}) async{
    final newHistory = <int, List<PaintContent>>{};
    final newUndoStack = <int, List<PaintContent>>{};
    final newTextBoxes = <int, List<TextBox>>{};
    _history.forEach((key, value) {
      if (isAdd) {
        newHistory[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Removed page, skip it
        } else {
          newHistory[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _undoStack.forEach((key, value) {
      if (isAdd) {
        newUndoStack[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Removed page, skip it
        } else {
          newUndoStack[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _textBoxes.forEach((key, value) {
      if (isAdd) {
        newTextBoxes[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Removed page, skip it
        } else {
          newTextBoxes[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    // Replace old maps with adjusted ones
    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);
    _textBoxes
      ..clear()
      ..addAll(newTextBoxes);

    // Adjust current page index if needed
    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners();
  }
}

class SimpleLine extends PaintContent {
  List<Offset> points = [];
  Color color; // New color for line

  SimpleLine(Offset startPoint, this.color) {
    points.add(startPoint);
  }

  @override
  void update(Offset newPoint) {
    points.add(newPoint);
  }

  @override
  void paintOnCanvas(Canvas canvas) {
    final paint =
        Paint()
          ..color =
              color // ✅ Use the stored color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
}

abstract class PaintContent {
  void paintOnCanvas(Canvas canvas);
  void update(Offset newPoint);
}

class DrawingPainter extends CustomPainter {
  final DrawingController controller;
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
