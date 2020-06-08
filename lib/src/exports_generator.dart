import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'decorators.dart';

// import 'utils.dart';

const _entrypointChecker = TypeChecker.fromRuntime(Entrypoint);
final emitter = DartEmitter();

String node_interop = 'package:node_interop/node.dart';
final setExport = refer('setExport', node_interop);

String js_lib = 'package:js/js.dart';
final allowInterop = refer('allowInterop', js_lib);

class ExportsGenerator extends Generator {
  Map<String, Map<String, dynamic>> a;

  ExportsGenerator(this.a);

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    var importDirectives = new List<Directive>();
    print("EXPORT: ${this.a.keys}");

    var annotated = library.allElements.where((element) {
      return _entrypointChecker.firstAnnotationOf(element) != null;
    }).toList();

    if (annotated.length != 1) {
      return null;
    }

    importDirectives.add(new Directive.import(node_interop));
    importDirectives.add(new Directive.import(js_lib));

    this.a.forEach((key, value) {
      Element element = value['element'];

      importDirectives.add(
          new Directive.import(library.pathToElement(element).toFilePath()));
    });

    var mainImportDirective = new Directive.import(
          library.pathToElement(annotated[0]).toFilePath(),
          as: 'entrypoint');

    importDirectives.add(mainImportDirective);

    final mainImported =
        refer("${mainImportDirective.as}.main", mainImportDirective.url);

    final main = Method((b) => b
      ..name = 'main'
      ..body = Block((b) {
        this.a.forEach((key, value) {

          b.addExpression(setExport.call([
            literalString(value['defaultConstructorName']),
            allowInterop.call([refer(value['defaultConstructorName'])])
          ]));

          b.addExpression(setExport.call([
            literalString(value['methodsMapperName']),
            allowInterop.call([refer(value['methodsMapperName'])])
          ]));
        });

        b.addExpression(mainImported.call([]));

        return b;
      }));

    var lib = new Library((b) => b
      ..directives.addAll(importDirectives)
      ..body.add(main));

    // var elem = this.a['defaultConstructorName'] as Map;
    // var element = elem['element'] as Element;

    return lib.accept(emitter).toString();
  }
}
