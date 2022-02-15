import 'dart:typed_data';

import 'package:ethereum_util/ethereum_util.dart';
import 'package:ethereum_util/src/signature.dart' as signature;

// secp256k1n/2
final BigInt N_DIV_2 = BigInt.parse(
  '7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0',
  radix: 16,
);

class TransactionOptions {
  /**
   * A Common object defining the chain and the hardfork a transaction belongs to.
   */
  final Common? common;

  /**
   * The chain of the transaction, default: 'mainnet'
   */
  final dynamic chain;

  /**
   * The hardfork of the transaction, default: 'petersburg'
   */
  final String? hardfork;

  const TransactionOptions({
    this.common,
    this.chain,
    this.hardfork,
  });
}

/**
 * An Ethereum transaction.
 */
class Transaction {
  final dynamic dataValue;

  Uint8List get nonce => this.getter(0);
  set nonce(v) => this.setter(v, 0);

  Uint8List get gasPrice => this.getter(1);
  set gasPrice(v) => this.setter(v, 1);

  Uint8List get gasLimit => this.getter(2);
  set gasLimit(v) => this.setter(v, 2);

  Uint8List get to => this.getter(3);
  set to(v) => this.setter(v, 3);

  Uint8List get value => this.getter(4);
  set value(v) => this.setter(v, 4);

  dynamic get data => this.getter(5);
  set data(v) => this.setter(v, 5);

  Uint8List get v => this.getter(6);
  set v(nv) {
    if (nv != null) {
      this._validateV(toBuffer(nv));
    }
    this.setter(nv, 6);
  }

  Uint8List get r => this.getter(7);
  set r(v) => this.setter(v, 7);

  Uint8List get s => this.getter(8);
  set s(v) => this.setter(v, 8);

  late Uint8List _from;
  Uint8List get from => this.getSenderAddress();

  TransactionOptions opts;
  List<Uint8List?>? raw;
  late ECDSASignature sig;
  late Function toJSON;

  late Uint8List? _senderPubKey;
  late Common _common;

  /**
   * Creates a new transaction from an object with its fields' values.
   *
   * @param data - A transaction can be initialized with its rlp representation, an array containing
   * the value of its fields in order, or an object containing them by name.
   *
   * @param opts - The transaction's options, used to indicate the chain and hardfork the
   * transactions belongs to.
   *
   * @note Transaction objects implement EIP155 by default. To disable it, use the constructor's
   * second parameter to set a chain and hardfork before EIP155 activation (i.e. before Spurious
   * Dragon.)
   *
   */
  Transaction({
    this.raw,
    this.dataValue,
    this.opts = const TransactionOptions(),
  }) {
    this.raw = this.raw ?? List.generate(9, (index) => null);
    this.data = this.dataValue;
    // instantiate Common class instance based on passed options
    if (opts.common != null) {
      if (opts.chain != null || opts.hardfork != null) {
        throw new ArgumentError(
          'Instantiation with both opts.common, and opts.chain and opts.hardfork parameter not allowed!',
        );
      }

      this._common = opts.common!;
    } else {
      dynamic chain = opts.chain != null ? opts.chain : 'mainnet';
      String? hardfork = opts.hardfork != null ? opts.hardfork : 'petersburg';

      this._common = new Common(chain, hardfork: hardfork);
    }

    // attached serialize
    defineProperties(this, fields, this.data);

    this._validateV(this.v);
  }

  operator [](String name) {
    switch (name) {
      case 'nonce':
        return this.nonce;
      case 'gasPrice':
        return this.gasPrice;
      case 'gasLimit':
        return this.gasLimit;
      case 'to':
        return this.to;
      case 'value':
        return this.value;
      case 'data':
        return this.data;
      case 'v':
        return this.v;
      case 'r':
        return this.r;
      case 's':
        return this.s;
    }
    throw ArgumentError("Property name $name doesn't exist");
  }

  operator []=(String name, dynamic value) {
    switch (name) {
      case 'nonce':
        this.nonce = value;
        break;
      case 'gasPrice':
        this.gasPrice = value;
        break;
      case 'gasLimit':
        this.gasLimit = value;
        break;
      case 'to':
        this.to = value;
        break;
      case 'value':
        this.value = value;
        break;
      case 'data':
        this.data = value;
        break;
      case 'v':
        this.v = value;
        break;
      case 'r':
        this.r = value;
        break;
      case 's':
        this.s = value;
        break;
      default:
        throw ArgumentError("Property name $name doesn't exist");
    }
  }

  getter(int i) {
    return this.raw![i];
  }

  setter(v, int i) {
    v = toBuffer(v);
    if (bufferToHex(v) == '00' &&
        fields[i]['allowZero'] != null &&
        !fields[i]['allowZero']) {
      v = Uint8List(0);
    }
    if (fields[i]['allowLess'] != null &&
        fields[i]['allowLess'] &&
        (fields[i]['length'] != null && fields[i]['length'] > 0)) {
      v = stripZeros(v);
      assert(
          fields[i]['length'] >= v.length,
          "The field " +
              fields[i]['name'] +
              " must not have more " +
              fields[i]['length'].toString() +
              " bytes");
    } else if (!(fields[i]['allowZero'] != null &&
            fields[i]['allowZero'] &&
            v.length == 0) &&
        (fields[i]['length'] != null && fields[i]['length'] > 0)) {
      assert(
          fields[i]['length'] == v.length,
          "The field " +
              fields[i]['name'] +
              " must have byte length of " +
              fields[i]['length'].toString());
    }
    this.raw![i] = v;
  }

  /**
   * If the tx's `to` is to the creation address
   */
  bool toCreationAddress() {
    return this.to.toString() == '';
  }

  /**
   * Computes a sha3-256 hash of the serialized tx
   * @param includeSignature - Whether or not to include the signature
   */
  Uint8List hash([bool includeSignature = true]) {
    var items;
    if (includeSignature) {
      items = this.raw;
    } else {
      if (this._implementsEIP155()) {
        items = [
          ...this.raw!.getRange(0, 6),
          toBuffer(this.getChainId()),
          // TODO: stripping zeros should probably be a responsibility of the rlp module
          stripZeros(toBuffer(0)),
          stripZeros(toBuffer(0)),
        ];
      } else {
        items = this.raw!.getRange(0, 6);
      }
    }

    // create hash
    return rlphash(items);
  }

  /**
   * returns chain ID
   */
  int getChainId() {
    return this._common.chainId();
  }

  /**
   * returns the sender's address
   */
  Uint8List getSenderAddress() {
    Uint8List? pubkey = this.getSenderPublicKey();
    this._from = publicKeyToAddress(pubkey!);
    return this._from;
  }

  /**
   * returns the public key of the sender
   */
  Uint8List? getSenderPublicKey() {
    if (!this.verifySignature()) {
      throw new ArgumentError('Invalid Signature');
    }

    // If the signature was verified successfully the _senderPubKey field is defined
    return this._senderPubKey;
  }

  /**
   * Determines if the signature is valid
   */
  bool verifySignature() {
    Uint8List msgHash = this.hash(false);
    // All transaction signatures whose s-value is greater than secp256k1n/2 are considered invalid.
    if (this._common.gteHardfork('homestead') &&
        readBytes(this.s).compareTo(N_DIV_2) == 1) {
      return false;
    }

    try {
      BigInt r = fromSigned(this.r);
      BigInt s = fromSigned(this.s);
      int v = bufferToInt(this.v);
      bool useChainIdWhileRecoveringPubKey = v >= this.getChainId() * 2 + 35 &&
          this._common.gteHardfork('spuriousDragon');
      this._senderPubKey = recoverPublicKeyFromSignature(
          ECDSASignature(r, s, v), msgHash,
          chainId: useChainIdWhileRecoveringPubKey ? this.getChainId() : null);
    } catch (e) {
      return false;
    }

    return this._senderPubKey != null;
  }

  /**
   * sign a transaction with a given private key
   * @param privateKey - Must be 32 bytes in length
   */
  sign(Uint8List privateKey) {
    // We clear any previous signature before signing it. Otherwise, _implementsEIP155's can give
    // different results if this tx was already signed.
    this.v = Uint8List(0);
    this.s = Uint8List(0);
    this.r = Uint8List(0);

    Uint8List msgHash = this.hash(false);
    ECDSASignature sig = signature.sign(msgHash, privateKey);

    var sigv = sig.v;
    if (this._implementsEIP155()) {
      sigv += this.getChainId() * 2 + 8;
    }

    this.v = toBuffer(sigv);
    this.s = toBuffer(sig.s);
    this.r = toBuffer(sig.r);
  }

  /**
   * Returns the rlp encoding of the transaction
   */
  Uint8List serialize() {
    // Note: This never gets executed, defineProperties overwrites it.
    return encode(this.raw);
  }

  void _validateV(Uint8List v) {
    if (v.length == 0) {
      return;
    }

    if (!this._common.gteHardfork('spuriousDragon')) {
      return;
    }

    int vInt = bufferToInt(v);

    if (vInt == 27 || vInt == 28) {
      return;
    }

    bool isValidEIP155V = vInt == this.getChainId() * 2 + 35 ||
        vInt == this.getChainId() * 2 + 36;

    if (!isValidEIP155V) {
      throw new ArgumentError(
          'Incompatible EIP155-based V ${vInt} and chain id ${this.getChainId()}. See the second parameter of the Transaction constructor to set the chain id.');
    }
  }

  bool _isSigned() {
    return this.v.length > 0 && this.r.length > 0 && this.s.length > 0;
  }

  bool _implementsEIP155() {
    bool onEIP155BlockOrLater = this._common.gteHardfork('spuriousDragon');

    if (!this._isSigned()) {
      // We sign with EIP155 all unsigned transactions after spuriousDragon
      return onEIP155BlockOrLater;
    }

    // EIP155 spec:
    // If block.number >= 2,675,000 and v = CHAIN_ID * 2 + 35 or v = CHAIN_ID * 2 + 36, then when computing
    // the hash of a transaction for purposes of signing or recovering, instead of hashing only the first six
    // elements (i.e. nonce, gasprice, startgas, to, value, data), hash nine elements, with v replaced by
    // CHAIN_ID, r = 0 and s = 0.
    int v = bufferToInt(this.v);

    var vAndChainIdMeetEIP155Conditions =
        v == this.getChainId() * 2 + 35 || v == this.getChainId() * 2 + 36;
    return vAndChainIdMeetEIP155Conditions && onEIP155BlockOrLater;
  }
}
