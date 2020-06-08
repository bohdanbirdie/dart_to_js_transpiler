# Dart to JavaScript Transpiler [Beta]

### Usage
- Add package to your dependencies
- Using decorators from this library mark classes and methods you're willing to expose as JS interface
  - Methods of the class that is not marked as exposed will be ignored
  - Only public methods can be exposed to JS
- Using `Entrypoint` decorator mark the `main` function
- Run `pub run build_runner build`
- Add `grinder` and `cli_pkg` to your dependencies
- Following the [example](https://github.com/bohdanbirdie/djt_example) create a `tool` folder in the root of the project, create `grind.dart` file inside.
- Create `package` folder in the root of the project, create `package.json` file following the template example
  - You can use `djt-codegen` lib to create templated JS files with `.d.ts` exports as wel
- Run `pub run grinder copy-schema` to create a JS build
  - `cd ./build/npm` and run `yarn && yarn codegen` in order yo create interfaces
- Your Dart library is now available as the NPM package.