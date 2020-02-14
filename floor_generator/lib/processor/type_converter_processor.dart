import 'package:analyzer/dart/element/element.dart';
import 'package:floor_generator/processor/error/type_converter_processor_error.dart';
import 'package:floor_generator/processor/processor.dart';
import 'package:floor_annotation/floor_annotation.dart' as annotations
    show TypeConverter;
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/value_object/type_converter.dart';
import 'package:analyzer/dart/element/visitor.dart';

class TypeConverterProcessor extends Processor<TypeConverter> {
  final ClassElement _classElement;
  final TypeConverterProcessorError _processorError;

  TypeConverterProcessor(final ClassElement classElement)
      : assert(classElement != null),
        _classElement = classElement,
        _processorError = TypeConverterProcessorError(classElement);

  @override
  TypeConverter process() {
    final visitor = TypeConverterMethodVisitor(_classElement);
    _classElement.visitChildren(visitor);
    final typeConverter = TypeConverter(_classElement, visitor.methodElements);
    if (!typeConverter.isProperlyConfigured()) {
      throw _processorError.TYPE_CONVERTER_IMPROPERLY_CONFIGURED;
    }
    return typeConverter;
  }
}

class TypeConverterMethodVisitor extends SimpleElementVisitor<dynamic> {
  List<MethodElement> methodElements = [];
  final ClassElement parentClassElement;

  TypeConverterMethodVisitor(this.parentClassElement);

  @override
  dynamic visitMethodElement(MethodElement element) {
    if (element.hasAnnotation(annotations.TypeConverter)) {
      if (element.isStatic &&
          element.parameters.length == 1 &&
          !element.parameters[0].type.isVoid &&
          !element.returnType.isVoid) {
        methodElements.add(element);
      } else {
        // show warning
        print(
            'The "${element.name}" method of class "${parentClassElement.name}" is annotated @TypeConverter but not static and it doesn\'t have one non-void parameter and a non-void return type.');
      }
    }
  }
}
