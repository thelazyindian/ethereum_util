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

const Map CHAINS = {
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
  static String name;
  static int chainId;
  static int networkId;
  static String comment;
  static String url;
  static GenesisBlock genesis;
  static List<Hardfork> hardforks;
  static List<BootstrapNode> bootstrapNodes;

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

  static getChain(Chain chain) {
    return chain;
  }
}

class GenesisBlock {
  static String hash;
  static String timestamp;
  static int gasLimit;
  static int difficulty;
  static String nonce;
  static String extraData;
  static String stateRoot;

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
  static String name;
  static int block;
  static String consensus;
  static dynamic finality;

  static fromJson(json) {
    name = json['name'];
    block = json['block'];
    consensus = json['consensus'];
    finality = json['finality'];
  }
}

class BootstrapNode {
  static String ip;
  static dynamic port;
  static String network;
  static int chainId;
  static String id;
  static String location;
  static String comment;

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
