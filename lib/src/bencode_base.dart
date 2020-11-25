import 'dart:convert';
import 'dart:typed_data';

///
/// Encode objects to bencoding format bytes;
///
/// This method comes from https://github.com/benjreinhart/bencode-js , just transfer JS to Dart
Uint8List encode(dynamic data, [dynamic buffer, int offset]) {
  if (data == null) return null;
  return _Encode(data, buffer, offset).encoding();
}

class _Encode {
  int bytes = -1;
  bool floatConversionDetected = false;
  final _data;
  var _buffer;
  final int _offset;

  var buffE = Uint8List.fromList(utf8.encode('e')); // Buffer.from('e');
  var buffD = Uint8List.fromList(utf8.encode('d')); //Buffer.from('d');
  var buffL = Uint8List.fromList(utf8.encode('l')); //Buffer.from('l');

  _Encode(this._data, [this._buffer, this._offset]);

  Uint8List encoding() {
    var buffers = <Uint8List>[];
    Uint8List result;

    _encode(buffers, _data);
    result =
        Uint8List.fromList(buffers.fold<List<int>>([], (previousValue, buffer) {
      previousValue.addAll(buffer);
      return previousValue;
    }));
    bytes = result.length;

    if (_buffer is Uint8List) {
      (_buffer as Uint8List).insertAll(_offset, result);
      return _buffer;
    }

    return result;
  }

  void _encode(buffers, data) {
    if (data == null) {
      return;
    }

    if (data is Uint8List) {
      buffer(buffers, data);
      return;
    }
    if (data is String) {
      string(buffers, data);
      return;
    }
    if (data is num) {
      number(buffers, data);
      return;
    }
    if (data is List) {
      list(buffers, data);
      return;
    }
    if (data is bool) {
      number(buffers, data ? 1 : 0);
      return;
    }
    if (data is Map) {
      dict(buffers, data);
      return;
    }
    // bencode.js can access ArrayBufferView and ArrayBuffer, I ignore these type:
    // case 'arraybufferview': buffer(buffers, Buffer.from(data.buffer, data.byteOffset, data.byteLength)); break;
    // case 'arraybuffer': buffer(buffers, Buffer.from(data)); break;
  }

  void buffer(buffers, Uint8List data) {
    buffers.add(Uint8List.fromList(utf8.encode('${data.length}:')));
    buffers.add(data);
  }

  void string(buffers, String data) {
    var bytesLength = Uint8List.fromList(utf8.encode(data)).lengthInBytes;
    buffers.add(Uint8List.fromList(utf8.encode('${bytesLength}:${data}')));
  }

  void number(buffers, data) {
    buffers.add(Uint8List.fromList(utf8.encode('i${data}e')));
  }

  void dict(buffers, data) {
    buffers.add(buffD);

    var j = 0;
    var k;
    var keys = (data as Map).keys.toList()..sort();
    var kl = keys.length;

    for (; j < kl; j++) {
      k = keys[j];
      if (data[k] == null) continue;
      string(buffers, k as String);
      _encode(buffers, data[k]);
    }

    buffers.add(buffE);
  }

  void list(buffers, data) {
    var i = 0;
    var c = data.length;
    buffers.add(buffL);

    for (; i < c; i++) {
      if (data[i] == null) continue;
      _encode(buffers, data[i]);
    }

    buffers.add(buffE);
  }
}

///
/// Decode bencoding format bytes to object.
///
/// This method comes from https://github.com/benjreinhart/bencode-js , just transfer JS to Dart
dynamic decode(Uint8List data, {int start, int end, String stringEncoding}) {
  if (data == null || data.isEmpty) {
    return null;
  } else {
    return _Decode(data, start: start, end: end, stringEncoding: stringEncoding)
        .next();
  }
}

class _Decode {
  static const int INTEGER_START = 0x69; // 'i'
  static const int STRING_DELIM = 0x3A; // ':'
  static const int DICTIONARY_START = 0x64; // 'd'
  static const int LIST_START = 0x6C; // 'l'
  static const int END_OF_TYPE = 0x65; // 'e'

  int _position = 0;
  String _stringEncoding;
  Uint8List _data;
  int _bytes = 0;

  _Decode(Uint8List data, {int start, int end, String stringEncoding}) {
    _data = data;
    _stringEncoding = stringEncoding?.toLowerCase();
    if (end != null && start != null) {
      _data = data.sublist(start, end);
    }
    _bytes = _data.length;
  }

  int getIntFromBuffer(Uint8List buffer, int start, int end) {
    var sum = 0;
    var sign = 1;

    for (var i = start; i < end; i++) {
      var num = buffer[i];

      if (num < 58 && num >= 48) {
        sum = sum * 10 + (num - 48);
        continue;
      }

      if (i == start && num == 43) {
        // +
        continue;
      }

      if (i == start && num == 45) {
        // -
        sign = -1;
        continue;
      }

      if (num == 46) {
        // .
        // its a float. break here.
        break;
      }

      throw Exception('not a number: buffer[$i] = $num');
    }
    return sum * sign;
  }

  dynamic next() {
    if (_data == null || _data.isEmpty) return null;
    switch (_data[_position]) {
      case DICTIONARY_START:
        return dictionary();
      case LIST_START:
        return list();
      case INTEGER_START:
        return integer();
      default:
        return buffer();
    }
  }

  int find(chr) {
    var i = _position;
    var c = _data.length;
    var d = _data;

    while (i < c) {
      if (d[i] == chr) return i;
      i++;
    }
    throw Exception(
        'Invalid data: Missing delimiter "${String.fromCharCode(chr)}" [0x${(chr as int).toRadixString(16)}]');
  }

  Map<String, dynamic> dictionary() {
    _position++;

    var dict = <String, dynamic>{};

    while (_data[_position] != END_OF_TYPE) {
      var keyBuffer = buffer();
      if (keyBuffer is! String) keyBuffer = utf8.decode(keyBuffer);
      dict[keyBuffer] = next();
    }

    _position++;

    return dict;
  }

  List list() {
    _position++;

    var lst = [];

    while (_data[_position] != END_OF_TYPE) {
      lst.add(next());
    }

    _position++;

    return lst;
  }

  int integer() {
    var end = find(END_OF_TYPE);
    var number = getIntFromBuffer(_data, _position + 1, end);

    _position += end + 1 - _position;

    return number;
  }

  dynamic buffer() {
    var sep = find(STRING_DELIM);
    var length = getIntFromBuffer(_data, _position, sep);
    var end = ++sep + length;

    _position = end;
    var sublist = _data.sublist(sep, end);
    var encoder =
        _stringEncoding == null ? null : Encoding.getByName(_stringEncoding);
    return encoder != null ? encoder.decode(sublist) : sublist;
  }
}
