library dart_to_js_transpiler;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_to_js_transpiler/src/exports_generator.dart';
import 'package:dart_to_js_transpiler/src/expose_generator.dart';
import 'package:dart_to_js_transpiler/src/schema_generator.dart';

export './src/decorators.dart';
export './grinder/tool.dart';

Map<String, Map<String, dynamic>> a = {};

Builder exposer(BuilderOptions options) =>
    SharedPartBuilder([ExposeGenerator(a)], 'exposer');

Builder exports(BuilderOptions options) =>
    LibraryBuilder(ExportsGenerator(a),
        generatedExtension: '.js.dart');

Builder schema(BuilderOptions options) =>
    LibraryBuilder(SchemaGenerator(a),
        generatedExtension: '.js', formatOutput: (code) => code);


