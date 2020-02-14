import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/misc/constants.dart';
import 'package:floor_generator/misc/type_utils.dart';

class TypeConverter {
  final ClassElement _classElement;
  final List<MethodElement> _methodElements;

  TypeConverter(this._classElement, this._methodElements);

  bool get hasMethods => _methodElements.isNotEmpty;

  bool hasMethodsToConvertType(DartType type) {
    return _methodElements.any((methodElement) =>
            methodElement.returnType == type &&
            methodElement.parameters[0].type.isSupported) &&
        _methodElements.any((methodElement) =>
            methodElement.returnType.isSupported &&
            methodElement.parameters[0].type == type);
  }

  @nonNull
  bool isProperlyConfigured() {
    // key is the dart type and the value is the supported sql type.
    // TODO: reinforce type checking here!!!!
    final Map<DartType, List<String>> typeMap = {};

    // get the unsupported type first.
    for (final methodElement in _methodElements) {
      if (!methodElement.returnType.isSupported) {
        typeMap[methodElement.returnType] = [];
      }
      if (!methodElement.parameters[0].type.isSupported) {
        if (!typeMap.containsKey(methodElement.parameters[0].type)) {
          typeMap[methodElement.returnType] = [];
        }
      }
    }

    // get the supported types.
    for (final methodElement in _methodElements) {
      if (methodElement.returnType.isSupported &&
          typeMap.containsKey(methodElement.parameters[0].type)) {
        typeMap[methodElement.parameters[0].type]
            .add(_getSqlType(methodElement.returnType));
      }
      if (methodElement.parameters[0].type.isSupported &&
          typeMap.containsKey(methodElement.returnType)) {
        typeMap[methodElement.returnType]
            .add(_getSqlType(methodElement.parameters[0].type));
      }
    }

    // those unsupported types must only one convertion to sql
    // check the set is it has more than one sql type or contains null
    return typeMap.isNotEmpty &&
        !typeMap.values.any(
            (sets) => sets.isEmpty && sets.length > 1 && sets.contains(null));
  }

  String _getSqlType(DartType type) {
    if (type.isDartCoreInt) {
      return SqlType.INTEGER;
    } else if (type.isDartCoreString) {
      return SqlType.TEXT;
    } else if (type.isDartCoreBool) {
      return SqlType.INTEGER;
    } else if (type.isDartCoreDouble) {
      return SqlType.REAL;
    }
    return null;
  }

  // return a sql type string if this converter can convert
  String canConvertTo(FieldElement fieldElement) {
    // find a method that can convert field to sql type.
    for (final methodElement in _methodElements) {
      // find toSqlType method
      if (methodElement.returnType.isSupported &&
          methodElement.parameters[0].type == fieldElement.type) {
        return _getSqlType(methodElement.returnType);
      }
    }
    return null;
  }

  String convertToDart(DartType fieldType, String value) {
    // search for the method with the Field type match to return type
    // and the param type is a supported sql type
    for (final methodElement in _methodElements) {
      if (methodElement.returnType == fieldType &&
          methodElement.parameters[0].type.isSupported) {
        return '${_classElement.displayName}.${methodElement.displayName}($value)';
      }
    }
    return null;
  }

  String convertToSql(DartType fieldType, String value) {
    // search for the method with the Field type match to param type
    // and return type is a supported sql type.
    for (final methodElement in _methodElements) {
      if (methodElement.returnType.isSupported &&
          methodElement.parameters[0].type == fieldType) {
        return '${_classElement.displayName}.${methodElement.displayName}($value)';
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeConverter &&
          runtimeType == other.runtimeType &&
          _classElement == other._classElement &&
          _methodElements == other._methodElements;

  @override
  // TODO: implement hashCode
  int get hashCode => _classElement.hashCode ^ _methodElements.hashCode;
}
