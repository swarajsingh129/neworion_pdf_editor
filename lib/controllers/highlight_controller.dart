import 'package:flutter/foundation.dart';
import 'package:neworion_pdf_editor/controllers/annotation_controller.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A controller that manages highlight and underline annotations
/// in a PDF document using the Syncfusion PDF viewer.
///
/// Supports undo/redo operations, page-based history, and dynamic page adjustments.
class HighlightController extends ChangeNotifier {
  /// Stores the annotation history per page.
  final Map<int, List<AnnotationAction>> _highlightHistory = {};

  /// Stores the undone annotation actions per page for redo functionality.
  final Map<int, List<AnnotationAction>> _highlightUndoStack = {};

  /// The current active page index.
  int _currentPage = 0;

  /// Returns the highlight history map.
  Map<int, List<AnnotationAction>> get getHighlightHistory => _highlightHistory;

  /// Sets the current page and initializes history stacks if not already present.
  void setPage(int page) {
    _currentPage = page;
    _highlightHistory.putIfAbsent(page, () => []);
    _highlightUndoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  /// Adds a new annotation to the current page.
  /// Clears the redo stack as a new action breaks the redo chain.
  void addAnnotation(AnnotationAction annotationAction) {
    _highlightHistory[_currentPage]!.add(annotationAction);
    _highlightUndoStack[_currentPage]!.clear();
    notifyListeners();
  }

  /// Undoes the last highlight/underline action on the current page.
  void undo(PdfViewerController pdfViewerController) {
    if (_highlightHistory[_currentPage]?.isNotEmpty == true) {
      var lastAction = _highlightHistory[_currentPage]!.removeLast();
      _highlightUndoStack[_currentPage]!.add(lastAction);
      pdfViewerController.removeAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  /// Redoes the last undone highlight/underline action on the current page.
  void redo(PdfViewerController pdfViewerController) {
    if (_highlightUndoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _highlightUndoStack[_currentPage]!.removeLast();
      _highlightHistory[_currentPage]!.add(lastAction);
      pdfViewerController.addAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  /// Clears all highlights/underlines from the current page.
  void clear(PdfViewerController pdfViewerController) {
    _highlightHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
    _highlightHistory[_currentPage]?.clear();
    _highlightUndoStack[_currentPage]?.clear();
    notifyListeners();
  }

  /// Temporarily hides all highlights/underlines on the current page.
  void hide(PdfViewerController pdfViewerController) {
    _highlightHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
  }

  /// Restores (unhides) all highlights/underlines on the current page.
  void unhide(PdfViewerController pdfViewerController) {
    _highlightHistory[_currentPage]?.forEach((action) {
      pdfViewerController.addAnnotation(action.annotation);
    });
  }

  /// Checks if there are any annotations available to undo or redo.
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _highlightUndoStack[_currentPage]?.isNotEmpty == true
        : _highlightHistory[_currentPage]?.isNotEmpty == true;
  }

  /// Checks if there are any annotations (in history or undo stack) to clear.
  bool hasClearContent() {
    return _highlightHistory[_currentPage]?.isNotEmpty == true ||
        _highlightUndoStack[_currentPage]?.isNotEmpty == true;
  }

  /// Clears all highlights/underlines across all pages.
  void clearAllPages(PdfViewerController pdfViewerController) {
    _highlightHistory.clear();
    _highlightUndoStack.clear();
    pdfViewerController.removeAllAnnotations();
    setPage(0);
    notifyListeners();
  }

  /// Adjusts the highlight and undo stacks when pages are added or removed.
  ///
  /// [pageIndex] - The index where the page was added or removed.
  /// [isAdd] - Whether a page was added (true) or removed (false).
  Future<void> adjustPages(
    int pageIndex,
    PdfViewerController pdfViewerController, {
    bool isAdd = true,
  }) async {
    final newHighlightHistory = <int, List<AnnotationAction>>{};
    final newHighlightUndoStack = <int, List<AnnotationAction>>{};

    _highlightHistory.forEach((key, value) {
      if (isAdd) {
        newHighlightHistory[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newHighlightHistory[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _highlightUndoStack.forEach((key, value) {
      if (isAdd) {
        newHighlightUndoStack[key >= pageIndex ? key + 1 : key] = value;
      } else {
        if (key != pageIndex) {
          newHighlightUndoStack[key > pageIndex ? key - 1 : key] = value;
        }
      }
    });

    _highlightHistory
      ..clear()
      ..addAll(newHighlightHistory);
    _highlightUndoStack
      ..clear()
      ..addAll(newHighlightUndoStack);

    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }

    // Restore annotations after page structure changes
    unhide(pdfViewerController);
    notifyListeners();
  }
}
