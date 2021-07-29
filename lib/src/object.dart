import 'dart:typed_data';

import 'package:ethereum_util/ethereum_util.dart';

defineProperties(self, fields, data) {
  self.raw = [];
  self._fields = [];
  // attach the `toJSON`
  self.toJSON = (label) {
    if (label == null) {
      label = false;
    }
    if (label) {
      var obj_1 = {};
      self._fields.forEach((field) {
        obj_1[field] = "0x" + self[field].toString('hex');
      });
      return obj_1;
    }
    return baToJSON(self.raw);
  };
  self.serialize = () {
    return encode(self.raw);
  };
  
  //   fields.forEach((field, i) {
  //     self._fields.push(field['name']);
  //     getter() {
  //         return self.raw[i];
  //     }
  //     setter(v) {
  //         v = toBuffer(v);
  //         if (v.toString('hex') == '00' && !field['allowZero']) {
  //             v = Uint8List(0);
  //         }
  //         if (field['allowLess'] && field.length > 0) {
  //             v = stripZeros(v);
  //             assert(field.length >= v.length, "The field " + field['name'] + " must not have more " + field.length + " bytes");
  //         }
  //         else if (!(field['allowZero'] && v.length === 0) && field.length) {
  //             assert(field.length == v.length, "The field " + field['name'] + " must have byte length of " + field.length);
  //         }
  //         self.raw[i] = v;
  //     }
  //     Object.defineProperty(self, field['name'], {
  //         enumerable: true,
  //         configurable: true,
  //         get: getter,
  //         set: setter,
  //     });
  //     if (field['default']) {
  //         self[field['name']] = field['default'];
  //     }
  // });

  fields.forEach((field, i) {
    self._fields.push(field['name']);
    if (field['default']) {
      self[field['name']] = field['default'];
    }
  });
  // if the constuctor is passed data
  if (data) {
    if (data is String) {
      data = Uint8List.fromList(toBuffer(stripHexPrefix(data)));
    }
    if (data is Uint8List) {
      data = decode(data);
    }
    if (data is List) {
      if (data.length > self._fields.length) {
        throw new ArgumentError('wrong number of fields in data');
      }
      // make sure all the items are buffers
      int i = 0;
      data.forEach((d) {
        self[self._fields[i++]] = toBuffer(d);
      });
    } else {
      throw new ArgumentError('invalid data');
    }
  }
}
