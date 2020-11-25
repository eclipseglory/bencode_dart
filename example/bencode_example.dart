import 'dart:convert';
import 'dart:typed_data';

import 'package:bencode_dart/bencode.dart' as bencode;

void main() {
  print(String.fromCharCodes(bencode.encode('string'))); // => "6:string"
  print(String.fromCharCodes(bencode.encode(123))); // => "i123e"
  print(
      String.fromCharCodes(bencode.encode(['str', 123]))); // => "l3:stri123ee"
  print(String.fromCharCodes(
      bencode.encode({'key': 'value'}))); // => "d3:key5:valuee"

  var map = bencode.decode(Uint8List.fromList(utf8.encode(
      'd3:key5:valuee')),stringEncoding: 'utf-8'); // => { key: "value" } , the string value is bytes array
  print(map);
}
