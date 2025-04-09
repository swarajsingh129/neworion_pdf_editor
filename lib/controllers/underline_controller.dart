import 'package:flutter/foundation.dart';
import 'package:neworion_pdf_editor_lite/controllers/annotation_controller.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UnderlineController extends ChangeNotifier {
  final Map<int, List<AnnotationAction>> _underlineHistory = {};
  final Map<int, List<AnnotationAction>> _underlineUndoStack = {};

  int _currentPage = 0;
  Map<int, List<AnnotationAction>> get getUnderlineHistory => _underlineHistory;
  void setPage(int page) {
    _currentPage = page;
    _underlineHistory.putIfAbsent(page, () => []);
    _underlineUndoStack.putIfAbsent(page, () => []);
    notifyListeners();
  }

  void addAnnotation(AnnotationAction annotationAction) {
    _underlineHistory[_currentPage]!.add(annotationAction);
    _underlineUndoStack[_currentPage]!
        .clear(); // Clear redo stack after new action
    notifyListeners();
  }

  // ✅ Undo for Underline
  void undo(PdfViewerController pdfViewerController) {
    if (_underlineHistory[_currentPage]?.isNotEmpty == true) {
      var lastAction = _underlineHistory[_currentPage]!.removeLast();
      _underlineUndoStack[_currentPage]!.add(lastAction);
      pdfViewerController.removeAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  // ✅ Redo for Underline
  void redo(PdfViewerController pdfViewerController) {
    if (_underlineUndoStack[_currentPage]?.isNotEmpty == true) {
      var lastAction = _underlineUndoStack[_currentPage]!.removeLast();
      _underlineHistory[_currentPage]!.add(lastAction);
      pdfViewerController.addAnnotation(lastAction.annotation);
      notifyListeners();
    }
  }

  // ✅ Clear Underline
  void clear(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
    _underlineHistory[_currentPage]?.clear();
    _underlineUndoStack[_currentPage]?.clear();
    notifyListeners();
  }

  hide(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.removeAnnotation(action.annotation);
    });
  }

  unhide(PdfViewerController pdfViewerController) {
    _underlineHistory[_currentPage]?.forEach((action) {
      pdfViewerController.addAnnotation(action.annotation);
    });
  }

  // ✅ Check if content exists
  bool hasContent({bool isRedo = false}) {
    return isRedo
        ? _underlineUndoStack[_currentPage]?.isNotEmpty == true
        : _underlineHistory[_currentPage]?.isNotEmpty == true;
  }

  bool hasClearContent() {
    return _underlineHistory[_currentPage]?.isNotEmpty == true ||
        _underlineUndoStack[_currentPage]?.isNotEmpty == true;
  }

  clearAllPages(PdfViewerController pdfViewerController) {
    _underlineHistory.clear();
    _underlineUndoStack.clear();
    pdfViewerController.removeAllAnnotations();

    setPage(0);
    notifyListeners();
  }

  adjustPages(
    int pageIndex,
    PdfViewerController pdfViewerController, {
    bool isAdd = true,
  }) async {
    final newUnderlineHistory = <int, List<AnnotationAction>>{};
    final newUnderlineUndoStack = <int, List<AnnotationAction>>{};

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

    _underlineHistory
      ..clear()
      ..addAll(newUnderlineHistory);
    _underlineUndoStack
      ..clear()
      ..addAll(newUnderlineUndoStack);

    if (!isAdd && _currentPage > pageIndex) {
      _currentPage -= 1;
    } else if (isAdd && _currentPage >= pageIndex) {
      _currentPage += 1;
    }
    unhide(pdfViewerController);

    notifyListeners();
  }
}
