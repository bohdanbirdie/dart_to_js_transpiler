// import 'dart:convert';
import 'dart:io';

// import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';

void addSchemaTasks() {
  addTask(GrinderTask('copy-schema', taskFunction: () async {
    File("src/main.js").copySync("build/npm/schema.js");
    print("  Copied schema");
  }, depends: ["pkg-npm-dev", "pkg-js-dev"]));
}
