import 'dart:typed_data';

import 'package:ethereum_util/ethereum_util.dart';

// Define Properties
final List<Map> fields = [
  {
    'name': 'nonce',
    'length': 32,
    'allowLess': true,
    'default': Uint8List(0),
  },
  {
    'name': 'gasPrice',
    'length': 32,
    'allowLess': true,
    'default': Uint8List(0),
  },
  {
    'name': 'gasLimit',
    'alias': 'gas',
    'length': 32,
    'allowLess': true,
    'default': Uint8List(0),
  },
  {
    'name': 'to',
    'allowZero': true,
    'length': 20,
    'default': Uint8List(0),
  },
  {
    'name': 'value',
    'length': 32,
    'allowLess': true,
    'default': Uint8List(0),
  },
  {
    'name': 'data',
    'alias': 'input',
    'allowZero': true,
    'default': Uint8List(0),
  },
  {
    'name': 'v',
    'allowZero': true,
    'default': Uint8List(0),
  },
  {
    'name': 'r',
    'length': 32,
    'allowZero': true,
    'allowLess': true,
    'default': Uint8List(0),
  },
  {
    'name': 's',
    'length': 32,
    'allowZero': true,
    'allowLess': true,
    'default': Uint8List(0),
  },
];

defineProperties(Transaction self, List<Map> fields, dynamic data) {
  List<String> _fields = [];
  int i = 0;
  // attach the `toJSON`
  self.toJSON = (label) {
    if (label == null) {
      label = false;
    }
    if (label) {
      var obj_1 = {};
      _fields.forEach((field) {
        obj_1[field] = bufferToHex(self[field]);
      });
      return obj_1;
    }
    return baToJSON(self.raw);
  };
  // self['serialize'] = () {
  //   return encode(self.raw);
  // };

  i = 0;
  fields.forEach((field) {
    _fields.add(field['name']);
    if (field['default'] != null) {
      self[field['name']] = field['default'];
    }
  });

  // if the constuctor is passed data
  if (data != null) {
    if (data is String) {
      data = Uint8List.fromList(toBuffer(stripHexPrefix(data)));
    }
    if (data is Uint8List) {
      data = decode(data);
    }
    if (data is List) {
      if (data.length > _fields.length) {
        throw new ArgumentError('wrong number of fields in data');
      }
      // make sure all the items are buffers
      i = 0;
      data.forEach((d) {
        self[_fields[i++]] = toBuffer(d);
      });
    } else {
      throw new ArgumentError('invalid data');
    }
  }
}
