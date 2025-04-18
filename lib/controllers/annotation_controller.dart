import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Defines the types of annotations supported.
///
/// [highlight] - Highlights the selected text.
/// [underline] - Underlines the selected text.
enum AnnotationType { highlight, underline }

/// Represents an action performed on an annotation.
///
/// Used for managing annotation history, undo/redo operations, and
/// distinguishing between adding or removing annotations.
class AnnotationAction {
  /// The annotation widget or object related to this action.
  final Annotation annotation;

  /// The type of annotation (highlight or underline).
  final AnnotationType type;

  /// Flag to indicate whether the action is an addition (`true`) or removal (`false`).
  final bool isAdd;

  /// List of corresponding [PdfTextMarkupAnnotation] objects
  /// created or affected during this action.
  final List<PdfTextMarkupAnnotation> pdfAnnotation;

  /// Creates an [AnnotationAction] with the given [annotation], [type], and [pdfAnnotation].
  ///
  /// By default, [isAdd] is `true`, indicating an add operation.
  AnnotationAction(
    this.annotation,
    this.type,
    this.pdfAnnotation, {
    this.isAdd = true,
  });
}
