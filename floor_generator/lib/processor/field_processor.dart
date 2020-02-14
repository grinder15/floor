import 'package:analyzer/dart/element/element.dart';
import 'package:floor_annotation/floor_annotation.dart' as annotations
    show ColumnInfo;
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/misc/constants.dart';
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/processor/processor.dart';
import 'package:floor_generator/value_object/field.dart';
import 'package:floor_generator/value_object/type_converter.dart';
import 'package:source_gen/source_gen.dart';

class FieldProcessor extends Processor<Field> {
  final FieldElement _fieldElement;
  final List<TypeConverter> _typeConverters;

  FieldProcessor(
      final FieldElement fieldElement, final List<TypeConverter> typeConverters)
      : assert(fieldElement != null),
        _fieldElement = fieldElement,
        _typeConverters = typeConverters;

  @nonNull
  @override
  Field process() {
    final name = _fieldElement.name;
    final hasColumnInfoAnnotation =
        _fieldElement.hasAnnotation(annotations.ColumnInfo);
    final columnName = _getColumnName(hasColumnInfoAnnotation, name);
    final isNullable = _getIsNullable(hasColumnInfoAnnotation);

    return Field(_fieldElement, name, columnName, isNullable, _getSqlType(),
        typeConverter: _getTypeConverter());
  }

  @nonNull
  String _getColumnName(bool hasColumnInfoAnnotation, String name) {
    return hasColumnInfoAnnotation
        ? _fieldElement
                .getAnnotation(annotations.ColumnInfo)
                .getField(AnnotationField.COLUMN_INFO_NAME)
                ?.toStringValue() ??
            name
        : name;
  }

  @nonNull
  bool _getIsNullable(bool hasColumnInfoAnnotation) {
    return hasColumnInfoAnnotation
        ? _fieldElement
                .getAnnotation(annotations.ColumnInfo)
                .getField(AnnotationField.COLUMN_INFO_NULLABLE)
                ?.toBoolValue() ??
            true
        : true; // all Dart fields are nullable by default
  }

  TypeConverter _getTypeConverter() {
    for (final typeConverter in _typeConverters) {
      if (typeConverter.hasMethodsToConvertType(_fieldElement.type)) {
        return typeConverter;
      }
    }
    return null;
  }

  @nonNull
  String _getSqlType() {
    final type = _fieldElement.type;
    if (type.isDartCoreInt) {
      return SqlType.INTEGER;
    } else if (type.isDartCoreString) {
      return SqlType.TEXT;
    } else if (type.isDartCoreBool) {
      return SqlType.INTEGER;
    } else if (type.isDartCoreDouble) {
      return SqlType.REAL;
    } else {
      // for unsupported type, try to search in type converters.
      for (final typeConverter in _typeConverters) {
        final sqlType = typeConverter.canConvertTo(_fieldElement);
        if (sqlType != null) {
          // OK I found it!!!!
          return sqlType;
        }
      }
    }
    throw InvalidGenerationSourceError(
      'Column type is not supported for $type. Try to define TypeConverter to convert that type to supported SQL types.',
      element: _fieldElement,
    );
  }
}
