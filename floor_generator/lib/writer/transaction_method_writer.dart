import 'package:code_builder/code_builder.dart';
import 'package:floor_generator/misc/annotation_expression.dart';
import 'package:floor_generator/value_object/transaction_method.dart';
import 'package:floor_generator/writer/writer.dart';

class TransactionMethodWriter implements Writer {
  final TransactionMethod method;

  TransactionMethodWriter(final this.method);

  @override
  Method write() {
    return Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..returns = refer(method.returnType.getDisplayString())
      ..name = method.name
      ..requiredParameters.addAll(_generateParameters())
      ..modifier = MethodModifier.async
      ..body = Code(_generateMethodBody()));
  }

  String _generateMethodBody() {
    final parameters =
        method.parameterElements.map((parameter) => parameter.name).join(', ');
    final methodCall = '${method.name}($parameters)';

    final methodBodyBuffer = StringBuffer();

    methodBodyBuffer
        .writeln('${method.returnType.getDisplayString()} returnValue;');
    methodBodyBuffer.writeln('if (database is sqflite.Transaction) {');
    methodBodyBuffer.write('returnValue = ');
    methodBodyBuffer.writeln('super.$methodCall;');
    methodBodyBuffer.writeln('} else {');
    methodBodyBuffer.writeln(
        'await (database as sqflite.Database).transaction<void>((transaction) async {');
    methodBodyBuffer.writeln(
        'final transactionDatabase = _\$${method.databaseName}(changeListener)..database = transaction;');
    methodBodyBuffer.write('returnValue = ');
    methodBodyBuffer
        .writeln('transactionDatabase.${method.daoFieldName}.$methodCall;');
    methodBodyBuffer.writeln('});');
    methodBodyBuffer.writeln('}');
    methodBodyBuffer.writeln('return await returnValue;');

    /*return '''
    if (database is sqflite.Transaction) {
      await super.$methodCall;
    } else {
      await (database as sqflite.Database).transaction<void>((transaction) async {
        final transactionDatabase = _\$${method.databaseName}(changeListener)..database = transaction;
        await transactionDatabase.${method.daoFieldName}.$methodCall;
      });
    }
    ''';*/
    return methodBodyBuffer.toString();
  }

  List<Parameter> _generateParameters() {
    return method.parameterElements.map((parameter) {
      return Parameter((builder) => builder
        ..name = parameter.name
        ..type = refer(parameter.type.getDisplayString()));
    }).toList();
  }
}
