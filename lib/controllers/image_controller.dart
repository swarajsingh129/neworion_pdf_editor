import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Controller to manage image addition, removal, undo/redo, and page adjustments.
class ImageController extends ChangeNotifier {
  final Map<int, List<ImageBox>> _imageBoxes = {}; // Stores images per page
  final Map<int, List<ImageAction>> _history =
      {}; // History for undo operations
  final Map<int, List<ImageAction>> _undoStack =
      {}; // Stack for redo operations

  int _currentPage = 0;

  /// Get images for the current page
  List<ImageBox> getImageBoxes() => _imageBoxes[_currentPage] ?? [];

  /// Get all images for all pages
  Map<int, List<ImageBox>> getAllImageBoxes() => _imageBoxes;

  /// Set the current page and initialize its data if not already present
  void setPage(int page) {
    _currentPage = page;
    _imageBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  /// Add an image to the current page
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

  /// Remove an image from the current page
  void removeImage(ImageBox imageBox) {
    _imageBoxes[_currentPage]?.remove(imageBox);
    _history[_currentPage]!.add(ImageAction(imageBox, isAdd: false));
    notifyListeners();
  }

  /// Undo the last image action
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

  /// Redo the last undone image action
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

  /// Check if there is content available for undo/redo
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _undoStack[_currentPage]?.isNotEmpty == true
        : _history[_currentPage]?.isNotEmpty == true;
  }

  /// Clear all images and actions on the current page
  void clear() {
    _imageBoxes[_currentPage]?.clear();
    _history[_currentPage]?.clear();
    _undoStack[_currentPage]?.clear();
    notifyListeners();
  }

  /// Check if clearable content exists
  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _imageBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  /// Clear all pages and reset controller
  void clearAllPages() {
    _imageBoxes.clear();
    _history.clear();
    _undoStack.clear();
    setPage(0);
    notifyListeners();
  }

  /// Adjust image mappings when a page is added or removed
  Future<void> adjustPages(int pageIndex, {bool isAdd = true}) async {
    final newImageBoxes = <int, List<ImageBox>>{};
    final newHistory = <int, List<ImageAction>>{};
    final newUndoStack = <int, List<ImageAction>>{};

    _imageBoxes.forEach((key, value) {
      if (isAdd) {
        newImageBoxes[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newImageBoxes[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

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

    _imageBoxes
      ..clear()
      ..addAll(newImageBoxes);
    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);

    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners();
  }
}

/// Represents an image with position, size, and rotation properties.
class ImageBox {
  Offset position;
  double width;
  double height;
  ui.Image image;
  double rotation;

  ImageBox({
    required this.position,
    required this.width,
    required this.height,
    required this.image,
    this.rotation = 0.0,
  });
}

/// Action model for managing undo/redo of images.
class ImageAction {
  final ImageBox imageBox;
  final bool isAdd;

  ImageAction(this.imageBox, {required this.isAdd});
}

/// Custom painter to draw an image on a canvas.
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
