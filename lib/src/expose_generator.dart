import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'decorators.dart';


const _exposeMethodChecker = TypeChecker.fromRuntime(ExposeMethod);

final jsify = refer('jsify', 'package:node_interop/util.dart');
final dartify = refer('dartify', 'package:node_interop/util.dart');
final allowInterop = refer('allowInterop', 'package:js/js.dart');
final setExport = refer('setExport', 'package:node_interop/node.dart');
final emitter = DartEmitter();

class ExposeGenerator extends GeneratorForAnnotation<ExposeClass> {
  Map<String, Map<String, dynamic>> a;

  ExposeGenerator(this.a);

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    String result = "";
    print("expose: ${element}");

    bool isClass = element.kind == ElementKind.CLASS;
    if (isClass) {
      ClassElement classElement = element as ClassElement;
      String defaultConstructorName = classElement.name + 'DefaultConstructor';
      String methodsMapperName = classElement.name + 'MethodsMapper';

      Map<String, Expression> jsifyMap = {};
      List<Map> astMethodsList = [];

      List<Parameter> requiredParameters = classElement
          .unnamedConstructor.parameters
          .where((element) => element.isPositional)
          .map((element) {
        return Parameter((b) => b
          ..name = element.displayName
          ..type = refer(element.type.toString()));
      }).toList();

      // List<Parameter> namedParameters = 
      Map<String, Expression> namedParameters = {};
      List namedParametersForJs = [];
      classElement.unnamedConstructor.parameters
          .where((element) => element.isNamed)
          .forEach((element) {
            namedParametersForJs.add({
                'name': element.name,
                'type': element.getDisplayString(withNullability: false)
              });
        
        namedParameters.putIfAbsent(element.displayName,
            () => refer('dartified').index(literalString(element.displayName)));
      });

      classElement.methods
          .where((element) =>
              _exposeMethodChecker.firstAnnotationOf(element) != null)
          .forEach((element) {
        List<Parameter> requiredMethodParameters = element.parameters
            .where((element) => element.isPositional)
            .map((element) {
          return Parameter((b) => b
            ..name = element.displayName
            ..type = refer(element.type.toString()));
        }).toList();

        Map<String, Expression> namedMethodParameters = {};
        List namedMethodParametersForJs = [];

        element.parameters
            .where((element) => element.isNamed)
            .forEach((element) {
              namedMethodParametersForJs.add({
                'name': element.name,
                'type': element.getDisplayString(withNullability: false)
              });
          namedMethodParameters.putIfAbsent(
              element.displayName,
              () =>
                  refer('dartified').index(literalString(element.displayName)));
        });

        astMethodsList.add({
          'name': element.displayName,
          'returnType': element.returnType.toString(),
          'positionalArgs': requiredMethodParameters.map((e) {
            return {'name': e.name, 'type': e.type.symbol};
          }).toList(),
          'namedArgs': namedMethodParametersForJs
        });

        if (namedMethodParameters.isNotEmpty) {
          jsifyMap.putIfAbsent(element.displayName, () {
            return allowInterop.call([
              Method((b) => b
                ..requiredParameters.addAll(requiredMethodParameters)
                ..optionalParameters.add(Parameter((b) => b
                  ..name = "namedArgs"
                  ..defaultTo = literalConstMap({}).code))
                ..body = Block((b) => b
                  ..addExpression(dartify
                      .call([refer("namedArgs")]).assignFinal('dartified'))
                  ..addExpression(refer('instance.${element.displayName}')
                      .call(
                          requiredMethodParameters
                              .map((e) => refer(e.name))
                              .toList(),
                          namedMethodParameters)
                      .returned))).closure
            ]);
          });
        } else {
          jsifyMap.putIfAbsent(
              element.displayName,
              () => allowInterop
                  .call([refer('instance.${element.displayName}')]));
        }
      });

      jsifyMap.putIfAbsent('#instance', () => refer('instance'));

      final defaultConstructor = Method((b) => b
        ..requiredParameters.addAll(requiredParameters)
        ..optionalParameters.add(Parameter((b) => b
          ..name = "namedArgs"
          ..defaultTo = literalConstMap({}).code))
        ..returns = refer(classElement.displayName)
        ..name = defaultConstructorName
        ..body = Block((b) => b
          ..addExpression(
              dartify.call([refer("namedArgs")]).assignFinal('dartified'))
          ..addExpression(refer(classElement.name)
              .call(requiredParameters.map((e) => refer(e.name)).toList(),
                  namedParameters)
              .returned)));

      final methodsMapper = Method((b) => b
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer(classElement.displayName)
          ..name = 'instance'))
        ..name = methodsMapperName
        ..body = Block((b) =>
            b..addExpression(jsify.call([literalMap(jsifyMap)]).returned)));



      result = result +
          defaultConstructor.accept(emitter).toString() +
          '\n ' +
          methodsMapper.accept(emitter).toString() +
          '\n ' +
          '//${element.source.uri}'
              '\n ' +
          '//${element.source.uri.fragment}';

      a.putIfAbsent(
          classElement.name,
          () => {
                'element': element,
                'defaultConstructorName': defaultConstructorName,
                'defaultConstructorMethod': {
                  'name': "constructor",
                  'returnType': '',
                  'positionalArgs': requiredParameters.map((e) {
                    return {'name': e.name, 'type': e.type.symbol};
                  }).toList(),
                  'namedArgs': namedParametersForJs,
                },
                'methodsMapperName': methodsMapperName,
                'methodsList': astMethodsList,
              });
    }

    return result;
  }
}
