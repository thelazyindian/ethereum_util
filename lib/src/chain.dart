import 'package:ethereum_util/src/chains/goerli.dart';
import 'package:ethereum_util/src/chains/kovan.dart';
import 'package:ethereum_util/src/chains/mainnet.dart';
import 'package:ethereum_util/src/chains/rinkeby.dart';
import 'package:ethereum_util/src/chains/ropsten.dart';
import 'package:ethereum_util/src/hardforks/byzantium.dart';
import 'package:ethereum_util/src/hardforks/chainstart.dart';
import 'package:ethereum_util/src/hardforks/constantinople.dart';
import 'package:ethereum_util/src/hardforks/dao.dart';
import 'package:ethereum_util/src/hardforks/homestead.dart';
import 'package:ethereum_util/src/hardforks/istanbul.dart';
import 'package:ethereum_util/src/hardforks/muirGlacier.dart';
import 'package:ethereum_util/src/hardforks/petersburg.dart';
import 'package:ethereum_util/src/hardforks/spuriousDragon.dart';
import 'package:ethereum_util/src/hardforks/tangerineWhistle.dart';

const Map chainParams = {
  'names': {
    '1': 'mainnet',
    '3': 'ropsten',
    '4': 'rinkeby',
    '42': 'kovan',
    '6284': 'goerli',
  },
  'mainnet': MAINNET,
  'ropsten': ROPSTEN,
  'rinkeby': RINKEBY,
  'kovan': KOVAN,
  'goerli': GOERLI,
};

const List<List> hardforkChanges = [
  ['chainstart', CHAINSTART],
  ['homestead', HOMESTEAD],
  ['dao', DAO],
  ['tangerineWhistle', TANGERINEWHISTLE],
  ['spuriousDragon', SPURIOUSDRAGON],
  ['byzantium', BYZANTIUM],
  ['constantinople', CONSTANTINOPLE],
  ['petersburg', PETERSBURG],
  ['istanbul', ISTANBUL],
  ['muirGlacier', MUIRGLACIER],
];

class Chain {
  static late String name;
  static late int chainId;
  static late int networkId;
  static late String comment;
  static late String url;
  static late GenesisBlock genesis;
  static late List<Hardfork> hardforks;
  static late List<BootstrapNode> bootstrapNodes;

  static fromJson(Map json) {
    name = json['name'];
    chainId = json['chainId'];
    networkId = json['networkId'];
    comment = json['comment'];
    url = json['url'];
    genesis = GenesisBlock.fromJson(json['genesis']);
    hardforks = json['hardforks']
        .map((Map harfork) => Hardfork.fromJson(harfork))
        .toList();
    bootstrapNodes = json['bootstrapNodes']
        .map((Map bootstrapNode) => BootstrapNode.fromJson(bootstrapNode))
        .toList();
  }

  static Map getChain(Map chain) {
    return chain;
  }
}

class GenesisBlock {
  static late String hash;
  static late String timestamp;
  static late int gasLimit;
  static late int difficulty;
  static late String nonce;
  static late String extraData;
  static late String stateRoot;

  static fromJson(json) {
    hash = json['name'];
    timestamp = json['timestamp'];
    gasLimit = json['gasLimit'];
    difficulty = json['difficulty'];
    nonce = json['nonce'];
    extraData = json['extraData'];
    stateRoot = json['stateRoot'];
  }
}

class Hardfork {
  static late String name;
  static late int block;
  static late String consensus;
  static late dynamic finality;

  static fromJson(json) {
    name = json['name'];
    block = json['block'];
    consensus = json['consensus'];
    finality = json['finality'];
  }
}

class BootstrapNode {
  static late String ip;
  static late dynamic port;
  static late String network;
  static late int chainId;
  static late String id;
  static late String location;
  static late String comment;

  static fromJson(json) {
    ip = json['ip'];
    port = json['port'];
    network = json['network'];
    chainId = json['chainId'];
    id = json['id'];
    location = json['location'];
    comment = json['comment'];
  }
}
