// import 'package:build/build.dart';
// import 'package:source_gen/source_gen.dart';

// import 'package:code_builder/code_builder.dart';
// import 'package:dart_style/dart_style.dart';

// class MemberCountLibraryGenerator extends Generator {
//   @override
//   String generate(LibraryReader library, BuildStep buildStep) {
//     var jsify = refer('jsify', 'package:node_interop/util.dart');
//     final emitter = DartEmitter();
//     Set<String> imports = new Set();

//     var lists = library.classes
//         .toList()
//         .where((classElement) => classElement.isPublic)
//         .map((classElement) {
//           print(
//               '\n${classElement.name} - ${classElement.source.shortName} - ${classElement.source.uri}\n');
//           imports.add("./${classElement.source.shortName}");

//           var methods = '{\n' +
//               classElement.methods
//                   .map((method) => "'${method.name}': instance.${method.name}")
//                   .toList()
//                   .join(',\n') +
//               '\n}';
//           var mapping = jsify.call([CodeExpression(Code(methods))]);

//           var classMapper = Method((b) => b
//             ..returns = refer('dynamic')
//             ..name = classElement.name + 'Constructor'
//             ..body = Code('''
//             var instance = new ${classElement.name}();
            
//             return ${mapping.accept(emitter)};
//             '''));

//           return classMapper.accept(emitter);
//         })
//         .toList()
//         .join("\n\n ");

//     var importDirectives = new List<Directive>();

//     importDirectives.add(new Directive.import(
//       'package:node_interop/util.dart',
//       show: ['jsify'],
//     ));

//     imports.forEach((import) {
//       importDirectives.add(new Directive.import(
//         import.toString(),
//       ));
//     });

//     var lib = new Library((b) => b..directives.addAll(importDirectives));
//     return DartFormatter().format('''
//     ${lib.accept(emitter)}
// $lists
// ''');
//   }
// }
