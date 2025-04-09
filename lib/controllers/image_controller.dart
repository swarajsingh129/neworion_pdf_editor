import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ImageController extends ChangeNotifier {
  final Map<int, List<ImageBox>> _imageBoxes = {};
  final Map<int, List<ImageAction>> _history = {};
  final Map<int, List<ImageAction>> _undoStack = {};
  int _currentPage = 0;
  // Get images for the current page
  List<ImageBox> getImageBoxes() => _imageBoxes[_currentPage] ?? [];
  Map<int, List<ImageBox>> getAllImageBoxes() => _imageBoxes;

  // Set current page
  void setPage(int page) {
    _currentPage = page;
    _imageBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  // Add image to the current page
  void addImage(ui.Image image) {
    double aspectRatio = image.width / image.height;
    double width = 150; // Default width
    double height = width / aspectRatio;

    ImageBox newImageBox = ImageBox(
      image: image,
      position: const Offset(100, 100),
      width: width,
      height: height,
    );
    _imageBoxes[_currentPage]!.add(newImageBox);
    _history[_currentPage]!.add(ImageAction(newImageBox, isAdd: true));
    notifyListeners();
  }

  // Remove image
  void removeImage(ImageBox imageBox) {
    _imageBoxes[_currentPage]?.remove(imageBox);
    _history[_currentPage]!.add(ImageAction(imageBox, isAdd: false));
    notifyListeners();
  }

  // Undo last action
  void undo() {
    if (_history[_currentPage]?.isNotEmpty == true) {
      var lastAction = _history[_currentPage]!.removeLast();
      _undoStack[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _imageBoxes[_currentPage]?.remove(lastAction.imageBox);
      } else {
        _imageBoxes[_currentPage]?.add(lastAction.imageBox);
      }
      notifyListeners();
    }
  }

  // Redo last undone action
  void redo() {
    if (_undoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _undoStack[_currentPage]!.removeLast();
      _history[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _imageBoxes[_currentPage]?.add(lastAction.imageBox);
      } else {
        _imageBoxes[_currentPage]?.remove(lastAction.imageBox);
      }
      notifyListeners();
    }
  }

  // Check if content is available
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _undoStack[_currentPage]?.isNotEmpty == true
        : _history[_currentPage]?.isNotEmpty == true;
  }

  // Clear all image actions
  void clear() {
    _imageBoxes[_currentPage]?.clear();
    _history[_currentPage]?.clear();
    _undoStack[_currentPage]?.clear();
    notifyListeners();
  }

  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _imageBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  clearAllPages() {
    _imageBoxes.clear();
    _history.clear();
    _undoStack.clear();
    setPage(0);
    notifyListeners();
  }

  adjustPages(int pageIndex, {bool isAdd = true}) async {
    final newImageBoxes = <int, List<ImageBox>>{};
    final newHistory = <int, List<ImageAction>>{};
    final newUndoStack = <int, List<ImageAction>>{};

    _imageBoxes.forEach((key, value) {
      if (isAdd) {
        newImageBoxes[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Skip deleted page
        } else {
          newImageBoxes[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _history.forEach((key, value) {
      if (isAdd) {
        newHistory[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Skip deleted page
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
          // Skip deleted page
        } else {
          newUndoStack[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    // Update maps
    _imageBoxes
      ..clear()
      ..addAll(newImageBoxes);
    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);

    // Adjust current page
    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners();
  }
}

// ✅ Image Box Class
class ImageBox {
  Offset position;
  double width;
  double height;
  ui.Image image;
  double rotation; // ✅ New rotation field

  ImageBox({
    required this.position,
    required this.width,
    required this.height,
    required this.image,
    this.rotation = 0.0, // ✅ Default rotation
  });
}

// ✅ Image Action for Undo/Redo
class ImageAction {
  final ImageBox imageBox;
  final bool isAdd;

  ImageAction(this.imageBox, {required this.isAdd});
}

class ImagePainter extends CustomPainter {
  final ImageBox imageBox;
  ImagePainter(this.imageBox);

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, imageBox.width, imageBox.height),
      image: imageBox.image,
      fit: BoxFit.contain,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
