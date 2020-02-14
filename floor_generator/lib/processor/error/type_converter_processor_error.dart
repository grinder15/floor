import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class TypeConverterProcessorError {
  final ClassElement _classElement;

  TypeConverterProcessorError(final ClassElement classElement)
      : assert(classElement != null),
        _classElement = classElement;

  // ignore: non_constant_identifier_names
  InvalidGenerationSourceError get TYPE_CONVERTER_IMPROPERLY_CONFIGURED {
    return InvalidGenerationSourceError(
      'Type converter ${_classElement.displayName} has no methods annotated or can convert Unsupported type to two or more Sql supported types.',
      todo:
          'Re-implement type converter to only convert unsupported type to one sql type only.',
      element: _classElement,
    );
  }
}
