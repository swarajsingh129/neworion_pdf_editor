import 'package:flutter/material.dart';
import 'package:neworion_pdf_editor_lite/controllers/drawing_controller.dart';

class TextBoxController extends ChangeNotifier {
  final Map<int, List<TextBox>> _textBoxes = {};
  final Map<int, List<TextBoxAction>> _history = {};
  final Map<int, List<TextBoxAction>> _undoStack = {};
  int _currentPage = 0;

  List<TextBox> getTextBoxes() => _textBoxes[_currentPage] ?? [];
  Map<int, List<TextBox>> getAllTextBoxes() => _textBoxes;

  void setPage(int page) {
    _currentPage = page;
    _textBoxes.putIfAbsent(page, () => []);
    _history.putIfAbsent(page, () => []);
    _undoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  TextBox? addTextBox() {
    _textBoxes[_currentPage] ??= [];
    TextBox newTextBox = TextBox("New Text", Offset(100, 100));
    _textBoxes[_currentPage]!.add(newTextBox);
    _history[_currentPage]!.add(TextBoxAction(newTextBox, isAdd: true));
    notifyListeners();
    return newTextBox;
  }

  void removeTextBox(TextBox textBox) {
    _textBoxes[_currentPage]?.remove(textBox);
    _history[_currentPage]!.add(TextBoxAction(textBox, isAdd: false));
    notifyListeners();
  }

  void selectTextBox(Offset tapPosition) {
    for (TextBox textBox in _textBoxes[_currentPage] ?? []) {
      Rect textBoxRect = Rect.fromLTWH(
        textBox.position.dx,
        textBox.position.dy,
        textBox.width,
        textBox.height,
      );

      if (textBoxRect.contains(tapPosition)) {
        notifyListeners();
        return;
      }
    }
  }

  void updateTextBox(
    TextBox textBox,
    String newText,
    double newFontSize,
    Color newColor,
  ) {
    textBox.text = newText;
    textBox.fontSize = newFontSize;
    textBox.color = newColor;
    notifyListeners();
  }

  void resizeTextBox(TextBox textBox, Offset delta) {
    textBox.width += delta.dx;
    textBox.height += delta.dy;
    textBox.width = textBox.width.clamp(20, double.infinity);
    textBox.height = textBox.height.clamp(20, double.infinity);
    notifyListeners();
  }

  void undo() {
    if (_history[_currentPage]?.isNotEmpty == true) {
      var lastAction = _history[_currentPage]!.removeLast();
      _undoStack[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _textBoxes[_currentPage]?.remove(lastAction.textBox);
      } else {
        _textBoxes[_currentPage]?.add(lastAction.textBox);
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_undoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _undoStack[_currentPage]!.removeLast();
      _history[_currentPage]!.add(lastAction);

      if (lastAction.isAdd) {
        _textBoxes[_currentPage]?.add(lastAction.textBox);
      } else {
        _textBoxes[_currentPage]?.remove(lastAction.textBox);
      }
      notifyListeners();
    }
  }

  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _undoStack[_currentPage]?.isNotEmpty == true
        : _history[_currentPage]?.isNotEmpty == true ||
            _textBoxes[_currentPage]?.isNotEmpty == true;
  }

  void clear() {
    _textBoxes[_currentPage] = [];
    _history[_currentPage] = [];
    _undoStack[_currentPage] = [];
    notifyListeners();
  }

  bool hasClearContent() {
    return _history[_currentPage]?.isNotEmpty == true ||
        _textBoxes[_currentPage]?.isNotEmpty == true ||
        _undoStack[_currentPage]?.isNotEmpty == true;
  }

  clearAllPages() {
    _history.clear();
    _undoStack.clear();
    _textBoxes.clear();
    setPage(0);
    notifyListeners();
  }

   adjustPages(int pageIndex, {bool isAdd = true}) async{
    final newTextBoxes = <int, List<TextBox>>{};
    final newHistory = <int, List<TextBoxAction>>{};
    final newUndoStack = <int, List<TextBoxAction>>{};

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

    // Replace with updated maps
    _textBoxes
      ..clear()
      ..addAll(newTextBoxes);
    _history
      ..clear()
      ..addAll(newHistory);
    _undoStack
      ..clear()
      ..addAll(newUndoStack);

    // Adjust current page if needed
    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    notifyListeners();
  }
}

class TextBoxAction extends PaintContent {
  final TextBox textBox;
  final bool isAdd;

  TextBoxAction(this.textBox, {required this.isAdd});

  @override
  void paintOnCanvas(Canvas canvas) {
    // No painting required for undo/redo actions
  }

  @override
  void update(Offset newPoint) {}
}

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
