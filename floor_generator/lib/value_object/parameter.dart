import 'package:analyzer/dart/element/element.dart';
import 'package:floor_generator/value_object/type_converter.dart';

class Parameter {
  final ParameterElement parameterElement;
  final TypeConverter typeConverter;

  Parameter(this.parameterElement, {this.typeConverter});
}
