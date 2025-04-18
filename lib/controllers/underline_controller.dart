import 'package:flutter/foundation.dart';
import 'package:neworion_pdf_editor/controllers/annotation_controller.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Controller to manage underlining annotations on the PDF
class UnderlineController extends ChangeNotifier {
  // History and undo stack for underline actions, keyed by page number
  final Map<int, List<AnnotationAction>> _underlineHistory = {};
  final Map<int, List<AnnotationAction>> _underlineUndoStack = {};

  // Current page being worked on
  int _currentPage = 0;

  // Getter for underline history
  Map<int, List<AnnotationAction>> get getUnderlineHistory => _underlineHistory;

  // Set the current page, initializing history and undo stack for that page if not present
  void setPage(int page) {
    _currentPage = page;
    _underlineHistory.putIfAbsent(page, () => []);
    _underlineUndoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  // Add a new underline annotation action to the history and clear redo stack
  void addAnnotation(AnnotationAction annotationAction) {
    _underlineHistory[_currentPage]!.add(annotationAction);
    _underlineUndoStack[_currentPage]!
        .clear(); // Clear redo stack after new action
    notifyListeners();
  }

  // Undo the last underline action, removing it from the PDF viewer
  void undo(PdfViewerController pdfViewerController) {
    if (_underlineHistory[_currentPage]?.isNotEmpty == true) {
      var lastAction = _underlineHistory[_currentPage]!.removeLast();
      _underlineUndoStack[_currentPage]!.add(lastAction);
      pdfViewerController.removeAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  // Redo the last undone underline action, re-adding it to the PDF viewer
  void redo(PdfViewerController pdfViewerController) {
    if (_underlineUndoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _underlineUndoStack[_currentPage]!.removeLast();
      _underlineHistory[_currentPage]!.add(lastAction);
      pdfViewerController.addAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  // Clear all underline annotations from the current page and reset the history and undo stack
  void clear(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
    _underlineHistory[_currentPage]?.clear();
    _underlineUndoStack[_currentPage]?.clear();
    notifyListeners();
  }

  // Hide all underline annotations without clearing the history
  void hide(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
  }

  // Unhide all underline annotations for the current page
  void unhide(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.addAnnotation(action.annotation);
    });
  }

  // Check if there is any content in the underline history or undo stack for the current page
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _underlineUndoStack[_currentPage]?.isNotEmpty == true
        : _underlineHistory[_currentPage]?.isNotEmpty == true;
  }

  // Check if there is any content in the history or undo stack or if annotations exist
  bool hasClearContent() {
    return _underlineHistory[_currentPage]?.isNotEmpty == true ||
        _underlineUndoStack[_currentPage]?.isNotEmpty == true;
  }

  // Clear all underline annotations across all pages
  void clearAllPages(PdfViewerController pdfViewerController) {
    _underlineHistory.clear();
    _underlineUndoStack.clear();
    pdfViewerController.removeAllAnnotations();
    setPage(0);
    notifyListeners();
  }

  // Adjust the underline annotations when a page is added or removed
  void adjustPages(
    int pageIndex,
    PdfViewerController pdfViewerController, {
    bool isAdd = true,
  }) async {
    final newUnderlineHistory = <int, List<AnnotationAction>>{};
    final newUnderlineUndoStack = <int, List<AnnotationAction>>{};

    // Adjust the history and undo stack to shift annotations accordingly
    _underlineHistory.forEach((key, value) {
      if (isAdd) {
        newUnderlineHistory[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Skip the deleted page
        } else {
          newUnderlineHistory[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _underlineUndoStack.forEach((key, value) {
      if (isAdd) {
        newUnderlineUndoStack[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key == pageIndex) {
          // Skip the deleted page
        } else {
          newUnderlineUndoStack[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    // Replace the old history and undo stack with the updated versions
    _underlineHistory
      ..clear()
      ..addAll(newUnderlineHistory);
    _underlineUndoStack
      ..clear()
      ..addAll(newUnderlineUndoStack);

    // Adjust the current page if necessary based on the operation
    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    // Ensure annotations are visible after the adjustment
    unhide(pdfViewerController);

    notifyListeners();
  }
}
