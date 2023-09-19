A Dart library for implementing the encoding and decoding of the Bencode format.

All codes come from [bencode.js][bencode.js], include example and test codes , I just transfer them to Dart code.

## Install

In your flutter or dart project add the dependency:

```
dependencies:
  b_encode_decode: ^1.0.3
```

## Usage

A simple usage example:

### Encode

Input parameter can be a String, Number, List, or Map. It will return a encoding bytes list ( `Uint8List` ).

```dart
import 'package:b_encode_decode/b_encode_decode.dart' as Bencode;

main() {
  Bencode.encode("string")         // => "6:string"
  Bencode.encode(123)              // => "i123e"
  Bencode.encode(["str", 123])     // => "l3:stri123ee"
  Bencode.encode({ "key": "value" }) // => "d3:key5:valuee"
}
```

### Decode

Input should be bytes list or String.

```dart
import 'package:b_encode_decode/b_encode_decode.dart' as Bencode;

main() {
  var map = Bencode.decode(Uint8List.fromList('d3:key5:valuee'.codeUnits); // => { key: "value" } , the string value is bytes array

  print(map);
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/moham96/b_encode_decode/issues
[bencode.js]: https://github.com/benjreinhart/bencode-js
