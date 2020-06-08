import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'decorators.dart';

// import 'utils.dart';

const _entrypointChecker = TypeChecker.fromRuntime(Entrypoint);
final emitter = DartEmitter();

// String node_interop = 'package:node_interop/node.dart';
// final setExport = refer('setExport', node_interop);

// String js_lib = 'package:js/js.dart';
// final allowInterop = refer('allowInterop', js_lib);

class SchemaGenerator extends Generator {
  Map<String, Map<String, dynamic>> a;

  SchemaGenerator(this.a);

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    print("SCHEMA: ${this.a.keys}");
    var importDirectives = new List<Directive>();

    var annotated = library.allElements.where((element) {
      return _entrypointChecker.firstAnnotationOf(element) != null;
    }).toList();

    if (annotated.length != 1) {
      return null;
    }

    this.a.forEach((key, value) {
      Element element = value['element'];

      importDirectives.add(
          new Directive.import(library.pathToElement(element).toFilePath()));
    });

    Map<String, Map<String, dynamic>> schema = this.a.map((key, value) {
      value.remove('element');
      return MapEntry(key, value);
    });


    return "const schema = ${json.encode(schema)};\n\n module.exports = { schema };";
  }
}

