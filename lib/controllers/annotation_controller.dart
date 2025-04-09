import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// ✅ Annotation Types
enum AnnotationType { highlight, underline }

// ✅ Annotation Action Class
class AnnotationAction {
  final Annotation annotation;
  final AnnotationType type;
  final bool isAdd;
  final List<PdfTextMarkupAnnotation> pdfAnnotation;

  AnnotationAction(
    this.annotation,
    this.type,
    this.pdfAnnotation, {
    this.isAdd = true,
  });
}
