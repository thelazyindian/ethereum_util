import 'dart:typed_data';

import 'package:ethereum_util/ethereum_util.dart';
import 'package:ethereum_util/src/signature.dart' as signature;
import 'package:ethereum_util/src/common.dart';

// secp256k1n/2
final BigInt N_DIV_2 = BigInt.parse(
  '7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0',
  radix: 16,
);

class TransactionOptions {
  /**
   * A Common object defining the chain and the hardfork a transaction belongs to.
   */
  Common common;

  /**
   * The chain of the transaction, default: 'mainnet'
   */
  dynamic chain;

  /**
   * The hardfork of the transaction, default: 'petersburg'
   */
  String hardfork;

  TransactionOptions({
    this.common,
    this.chain,
    this.hardfork,
  });
}

/**
 * An Ethereum transaction.
 */
class Transaction {
  final List<Uint8List> raw;
  final Uint8List nonce;
  final Uint8List gasLimit;
  final Uint8List gasPrice;
  final Uint8List to;
  final Uint8List value;
  final dynamic data;
  final TransactionOptions opts;

  Uint8List r;
  Uint8List s;
  Uint8List _v;
  Uint8List get v => this._v;
  set v(nv) {
    if (nv != null) {
      this._validateV(toBuffer(v));
    }
    this._v = nv;
  }

  ECDSASignature sig;

  Uint8List _senderPubKey;
  Uint8List _from;
  Common _common;

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
    this.data,
    this.gasLimit,
    this.gasPrice,
    this.nonce,
    this.to,
    this.value,
    this.opts,
  }) {
    // instantiate Common class instance based on passed options
    if (opts.common != null) {
      if (opts.chain != null || opts.hardfork != null) {
        throw new ArgumentError(
          'Instantiation with both opts.common, and opts.chain and opts.hardfork parameter not allowed!',
        );
      }

      this._common = opts.common;
    } else {
      dynamic chain = opts.chain != null ? opts.chain : 'mainnet';
      String hardfork = opts.hardfork != null ? opts.hardfork : 'petersburg';

      this._common = new Common(chain, hardfork: hardfork);
    }

    // Define Properties
    final fields = [
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

    // attached serialize
    defineProperties(this, fields, this.data);

    this._validateV(this.v);
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
          ...this.raw.getRange(0, 6),
          toBuffer(this.getChainId()),
          // TODO: stripping zeros should probably be a responsibility of the rlp module
          stripZeros(toBuffer(0)),
          stripZeros(toBuffer(0)),
        ];
      } else {
        items = this.raw.getRange(0, 6);
      }
    }

    // create hash
    return rlphash(items);
  }

  /**
   * returns chain ID
   */
  int getChainId() {
    return null; //this._common.chainId();
  }

  /**
   * returns the sender's address
   */
  Uint8List getSenderAddress() {
    if (this._from != null) {
      return this._from;
    }
    Uint8List pubkey = this.getSenderPublicKey();
    this._from = publicKeyToAddress(pubkey);
    return this._from;
  }

  /**
   * returns the public key of the sender
   */
  Uint8List getSenderPublicKey() {
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

    if (this._implementsEIP155()) {
      sig.v += this.getChainId() * 2 + 8;
    }

    this.sig = sig;
  }

  /**
   * Returns the rlp encoding of the transaction
   */
  Uint8List serialize() {
    // Note: This never gets executed, defineProperties overwrites it.
    return encode(this.raw);
  }

  void _validateV(Uint8List v) {
    if (v == null || v.length == 0) {
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
    var onEIP155BlockOrLater = this._common.gteHardfork('spuriousDragon');

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
