import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor/controllers/drawing_controller.dart';

/// The TextBoxController is responsible for managing text boxes on each PDF page.
/// It handles actions like adding, removing, selecting, resizing, and updating text boxes.
class TextBoxController extends ChangeNotifier {
  // A map to hold text boxes for each page.
  final Map<int, List<TextBox>> _textBoxes = {};

  // A map to store the history of actions for undo/redo functionality.
  final Map<int, List<TextBoxAction>> _history = {};

  // A map to store actions that can be undone (undo stack).
  final Map<int, List<TextBoxAction>> _undoStack = {};

  // Current page being worked on.
  int _currentPage = 0;

  // Getter to fetch text boxes of the current page.
  List<TextBox> getTextBoxes() => _textBoxes[_currentPage] ?? [];

  // Getter to fetch all text boxes across pages.
  Map<int, List<TextBox>> getAllTextBoxes() => _textBoxes;

  /// Sets the current page for the controller and initializes the necessary data structures.
  void setPage(int page) {
    _currentPage = page;
    _textBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners(); // Notify listeners to update UI or other components.
  }

  /// Adds a new text box on the current page and records the action in history.
  TextBox? addTextBox() {
    _textBoxes[_currentPage] ??= [];
    TextBox newTextBox = TextBox(
      "New Text",
      Offset(100, 100),
    ); // Default position and text.
    _textBoxes[_currentPage]!.add(newTextBox);
    _history[_currentPage]!.add(
      TextBoxAction(newTextBox, isAdd: true),
    ); // Record action.
    notifyListeners(); // Notify listeners about the change.
    return newTextBox;
  }

  /// Removes a text box from the current page and records the action in history.
  void removeTextBox(TextBox textBox) {
    _textBoxes[_currentPage]?.remove(textBox);
    _history[_currentPage]!.add(
      TextBoxAction(textBox, isAdd: false),
    ); // Record action.
    notifyListeners(); // Notify listeners.
  }

  /// Selects a text box based on the tap position and triggers a UI update if selected.
  void selectTextBox(Offset tapPosition) {
    for (TextBox textBox in _textBoxes[_currentPage] ?? []) {
      Rect textBoxRect = Rect.fromLTWH(
        textBox.position.dx,
        textBox.position.dy,
        textBox.width,
        textBox.height,
      );

      if (textBoxRect.contains(tapPosition)) {
        notifyListeners(); // Notify if a text box is selected.
        return;
      }
    }
  }

  /// Updates the properties of a text box (text, font size, color).
  void updateTextBox(
    TextBox textBox,
    String newText,
    double newFontSize,
    Color newColor,
  ) {
    textBox.text = newText;
    textBox.fontSize = newFontSize;
    textBox.color = newColor;
    notifyListeners(); // Notify listeners about the text box update.
  }

  /// Resizes a text box based on the delta values and ensures the width/height do not shrink below a threshold.
  void resizeTextBox(TextBox textBox, Offset delta) {
    textBox.width += delta.dx;
    textBox.height += delta.dy;
    textBox.width = textBox.width.clamp(
      20,
      double.infinity,
    ); // Min width of 20.
    textBox.height = textBox.height.clamp(
      20,
      double.infinity,
    ); // Min height of 20.
    notifyListeners(); // Notify listeners after resizing.
  }

  /// Performs undo by removing the last action from history and applying the reverse action.
  void undo() {
    if (_history[_currentPage]?.isNotEmpty == true) {
      var lastAction = _history[_currentPage]!.removeLast();
      _undoStack[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _textBoxes[_currentPage]?.remove(
          lastAction.textBox,
        ); // Remove added text box.
      } else {
        _textBoxes[_currentPage]?.add(
          lastAction.textBox,
        ); // Re-add removed text box.
      }
      notifyListeners(); // Notify listeners after undo.
    }
  }

  /// Performs redo by reapplying the last undone action.
  void redo() {
    if (_undoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _undoStack[_currentPage]!.removeLast();
      _history[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _textBoxes[_currentPage]?.add(lastAction.textBox); // Re-add text box.
      } else {
        _textBoxes[_currentPage]?.remove(
          lastAction.textBox,
        ); // Remove text box.
      }
      notifyListeners(); // Notify listeners after redo.
    }
  }

  /// Checks if there is any content in history or text boxes for the current page.
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _undoStack[_currentPage]?.isNotEmpty ==
            true // Check redo stack.
        : _history[_currentPage]?.isNotEmpty == true ||
            _textBoxes[_currentPage]?.isNotEmpty ==
                true; // Check history or text boxes.
  }

  /// Clears all content (text boxes, history, undo stack) for the current page.
  void clear() {
    _textBoxes[_currentPage] = [];
    _history[_currentPage] = [];
    _undoStack[_currentPage] = [];
    notifyListeners(); // Notify listeners after clearing.
  }

  /// Checks if there is any content (history or undo stack) for the current page.
  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  /// Clears all pages' content (text boxes, history, undo stack).
  clearAllPages() {
    _history.clear();
    _undoStack.clear();
    _textBoxes.clear();
    setPage(0); // Reset to page 0.
    notifyListeners(); // Notify listeners after clearing all pages.
  }

  /// Adjusts the page data when a page is added or removed.
  Future<void> adjustPages(int pageIndex, {bool isAdd = true}) async {
    final newTextBoxes = <int, List<TextBox>>{};
    final newHistory = <int, List<TextBoxAction>>{};
    final newUndoStack = <int, List<TextBoxAction>>{};

    // Adjust text boxes, history, and undo stack for each page.
    _textBoxes.forEach((key, value) {
      if (isAdd) {
        newTextBoxes[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Skip deleted page
        } else {
          newTextBoxes[key > pageIndex ? key - 1 : key] = value;
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

    // Replace with updated maps.
    _textBoxes
      ..clear()
      ..addAll(newTextBoxes);
    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);

    // Adjust the current page based on the operation.
    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners(); // Notify listeners after adjusting pages.
  }
}

/// The TextBoxAction represents an action performed on a text box (add/remove) to support undo/redo functionality.
class TextBoxAction extends PaintContent {
  final TextBox textBox;
  final bool isAdd;

  TextBoxAction(this.textBox, {required this.isAdd});

  @override
  void paintOnCanvas(Canvas canvas) {
    // No painting required for undo/redo actions.
  }

  @override
  void update(Offset newPoint) {}
}

/// Represents a text box with properties such as text, position, size, and color.
class TextBox {
  String text;
  Offset position;
  double width;
  double height;
  double fontSize;
  Color? color;

  TextBox(
    this.text,
    this.position, {
    this.width = 100,
    this.height = 50,
    this.fontSize = 12,
    this.color,
  });
}
