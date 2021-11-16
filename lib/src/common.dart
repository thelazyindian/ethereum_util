import 'package:ethereum_util/src/chain.dart';
import 'package:ethereum_util/src/transaction.dart';

class HardforkOptions {
  /** optional, only allow supported HFs (default: false) */
  final bool onlySupported;
  /** optional, only active HFs (default: false) */
  final bool onlyActive;

  HardforkOptions({
    this.onlySupported = false,
    this.onlyActive = false,
  });
}

/**
 * Common class to access chain and hardfork parameters
 */
class Common {
  final dynamic chain;
  final String? hardfork;
  final List<String>? supportedHardforks;

  late String? _hardfork;
  late List<String>? _supportedHardforks;
  late Map _chainParams;

  /**
   * @constructor
   * @param chain String ('mainnet') or Number (1) chain
   * @param hardfork String identifier ('byzantium') for hardfork (optional)
   * @param supportedHardforks Limit parameter returns to the given hardforks (optional)
   */
  Common(
    this.chain, {
    this.hardfork,
    this.supportedHardforks,
  }) {
    this._chainParams = this.setChain(chain);
    this._hardfork = null;
    this._supportedHardforks =
        supportedHardforks == null ? [] : supportedHardforks;
    if (hardfork != null) {
      this.setHardfork(hardfork);
    }
  }

  /**
   * Creates a Common object for a custom chain, based on a standard one. It uses all the [[Chain]]
   * params from [[baseChain]] except the ones overridden in [[customChainParams]].
   *
   * @param baseChain The name (`mainnet`) or id (`1`) of a standard chain used to base the custom
   * chain params on.
   * @param customChainParams The custom parameters of the chain.
   * @param hardfork String identifier ('byzantium') for hardfork (optional)
   * @param supportedHardforks Limit parameter returns to the given hardforks (optional)
   */
  // static forCustomChain(
  //   dynamic baseChain,
  //   Partial<Chain> customChainParams,
  //   {String hardfork,
  //   List<String> supportedHardforks,
  // }) {
  //   var standardChainParams = Common._getChainParams(baseChain);

  //   return new Common(
  //     {
  //       ...standardChainParams,
  //       ...customChainParams,
  //     },
  //     hardfork: hardfork,
  //     supportedHardforks: supportedHardforks,
  //   )
  // }

  static Map _getChainParams(String chain) {
    if (chain is int) {
      if (chainParams['names'][chain] != null) {
        return chainParams[chainParams['names'][chain]];
      }

      throw new ArgumentError('Chain with ID ${chain} not supported');
    }

    if (chainParams[chain] != null) {
      return chainParams[chain];
    }

    throw new ArgumentError('Chain with name ${chain} not supported');
  }

  /**
   * Sets the chain
   * @param chain String ('mainnet') or Number (1) chain
   *     representation. Or, a Dictionary of chain parameters for a private network.
   * @returns The dictionary with parameters set as chain
   */
  Map setChain(dynamic chain) {
    if (chain is int || chain is String) {
      this._chainParams = Common._getChainParams(chain);
    } else if (chain is Map) {
      List<String> required = [
        'networkId',
        'genesis',
        'hardforks',
        'bootstrapNodes'
      ];
      for (var param in required) {
        if (chain[param] == null) {
          throw new ArgumentError('Missing required chain parameter: ${param}');
        }
      }
      this._chainParams = chain;
    } else {
      throw new ArgumentError('Wrong input format');
    }
    return this._chainParams;
  }

  /**
   * Sets the hardfork to get params for
   * @param hardfork String identifier ('byzantium')
   */
  setHardfork(String? hardfork) {
    if (!this._isSupportedHardfork(hardfork)) {
      throw new ArgumentError(
          'Hardfork ${hardfork} not set as supported in supportedHardforks');
    }
    bool changed = false;
    for (var hfChanges in hardforkChanges) {
      if (hfChanges[0] == hardfork) {
        this._hardfork = hardfork;
        changed = true;
      }
    }
    if (!changed) {
      throw new ArgumentError('Hardfork with name ${hardfork} not supported');
    }
  }

  /**
   * Internal helper function to choose between hardfork set and hardfork provided as param
   * @param hardfork Hardfork given to function as a parameter
   * @returns Hardfork chosen to be used
   */
  String? _chooseHardfork({String? hardfork, bool? onlySupported}) {
    onlySupported = onlySupported == null ? true : onlySupported;
    if (hardfork == null) {
      if (this._hardfork == null) {
        throw new ArgumentError(
            'Method called with neither a hardfork set nor provided by param');
      } else {
        hardfork = this._hardfork;
      }
    } else if (onlySupported && !this._isSupportedHardfork(hardfork)) {
      throw new ArgumentError(
          'Hardfork ${hardfork} not set as supported in supportedHardforks');
    }
    return hardfork;
  }

  /**
   * Internal helper function, returns the params for the given hardfork for the chain set
   * @param hardfork Hardfork name
   * @returns Dictionary with hardfork params
   */
  // _getHardfork(hardfork: string): any {
  //   const hfs = this.hardforks()
  //   for (const hf of hfs) {
  //     if (hf['name'] === hardfork) return hf
  //   }
  //   throw new Error(`Hardfork ${hardfork} not defined for chain ${this.chainName()}`)
  // }

  /**
   * Internal helper function to check if a hardfork is set to be supported by the library
   * @param hardfork Hardfork name
   * @returns True if hardfork is supported
   */
  bool _isSupportedHardfork(String? hardfork) {
    if (this._supportedHardforks!.length > 0) {
      for (var supportedHf in this._supportedHardforks!) {
        if (hardfork == supportedHf) return true;
      }
    } else {
      return true;
    }
    return false;
  }

  /**
   * Returns the parameter corresponding to a hardfork
   * @param topic Parameter topic ('gasConfig', 'gasPrices', 'vm', 'pow', 'casper', 'sharding')
   * @param name Parameter name (e.g. 'minGasLimit' for 'gasConfig' topic)
   * @param hardfork Hardfork name, optional if hardfork set
   */
  // param(topic: string, name: string, hardfork?: string): any {
  //   hardfork = this._chooseHardfork(hardfork)

  //   let value
  //   for (const hfChanges of hardforkChanges) {
  //     if (!hfChanges[1][topic]) {
  //       throw new Error(`Topic ${topic} not defined`)
  //     }
  //     if (hfChanges[1][topic][name] !== undefined) {
  //       value = hfChanges[1][topic][name].v
  //     }
  //     if (hfChanges[0] === hardfork) break
  //   }
  //   if (value === undefined) {
  //     throw new Error(`${topic} value for ${name} not found`)
  //   }
  //   return value
  // }

  /**
   * Returns a parameter for the hardfork active on block number
   * @param topic Parameter topic
   * @param name Parameter name
   * @param blockNumber Block number
   */
  // paramByBlock(topic: string, name: string, blockNumber: number): any {
  //   const activeHfs = this.activeHardforks(blockNumber)
  //   const hardfork = activeHfs[activeHfs.length - 1]['name']
  //   return this.param(topic, name, hardfork)
  // }

  /**
   * Checks if set or provided hardfork is active on block number
   * @param hardfork Hardfork name or null (for HF set)
   * @param blockNumber
   * @param opts Hardfork options (onlyActive unused)
   * @returns True if HF is active on block number
   */
  // hardforkIsActiveOnBlock(
  //   hardfork: string | null,
  //   blockNumber: number,
  //   opts?: hardforkOptions,
  // ): boolean {
  //   opts = opts !== undefined ? opts : {}
  //   const onlySupported = opts.onlySupported === undefined ? false : opts.onlySupported
  //   hardfork = this._chooseHardfork(hardfork, onlySupported)
  //   const hfBlock = this.hardforkBlock(hardfork)
  //   if (hfBlock !== null && blockNumber >= hfBlock) return true
  //   return false
  // }

  /**
   * Alias to hardforkIsActiveOnBlock when hardfork is set
   * @param blockNumber
   * @param opts Hardfork options (onlyActive unused)
   * @returns True if HF is active on block number
   */
  // activeOnBlock(blockNumber: number, opts?: hardforkOptions): boolean {
  //   return this.hardforkIsActiveOnBlock(null, blockNumber, opts)
  // }

  /**
   * Sequence based check if given or set HF1 is greater than or equal HF2
   * @param hardfork1 Hardfork name or null (if set)
   * @param hardfork2 Hardfork name
   * @param opts Hardfork options
   * @returns True if HF1 gte HF2
   */
  bool hardforkGteHardfork(
    String? hardfork1,
    String hardfork2, {
    HardforkOptions? opts,
  }) {
    opts = opts != null ? opts : HardforkOptions();
    bool onlyActive = opts.onlyActive == null ? false : opts.onlyActive;
    hardfork1 = this._chooseHardfork(
        hardfork: hardfork1, onlySupported: opts.onlySupported);

    var hardforks;
    if (onlyActive) {
      hardforks = this.activeHardforks(opts: opts);
    } else {
      hardforks = this.hardforks();
    }

    int posHf1 = -1, posHf2 = -1;
    int index = 0;
    for (var hf in hardforks) {
      if (hf['name'] == hardfork1) posHf1 = index;
      if (hf['name'] == hardfork2) posHf2 = index;
      index += 1;
    }
    return posHf1 >= posHf2;
  }

  /**
   * Alias to hardforkGteHardfork when hardfork is set
   * @param hardfork Hardfork name
   * @param opts Hardfork options
   * @returns True if hardfork set is greater than hardfork provided
   */
  bool gteHardfork(String hardfork, {HardforkOptions? opts}) {
    return this.hardforkGteHardfork(null, hardfork, opts: opts);
  }

  /**
   * Checks if given or set hardfork is active on the chain
   * @param hardfork Hardfork name, optional if HF set
   * @param opts Hardfork options (onlyActive unused)
   * @returns True if hardfork is active on the chain
   */
  // hardforkIsActiveOnChain(hardfork?: string | null, opts?: hardforkOptions): boolean {
  //   opts = opts !== undefined ? opts : {}
  //   const onlySupported = opts.onlySupported === undefined ? false : opts.onlySupported
  //   hardfork = this._chooseHardfork(hardfork, onlySupported)
  //   for (const hf of this.hardforks()) {
  //     if (hf['name'] === hardfork && hf['block'] !== null) return true
  //   }
  //   return false
  // }

  /**
   * Returns the active hardfork switches for the current chain
   * @param blockNumber up to block if provided, otherwise for the whole chain
   * @param opts Hardfork options (onlyActive unused)
   * @return Array with hardfork arrays
   */
  List activeHardforks({int? blockNumber, HardforkOptions? opts}) {
    opts = opts != null ? opts : HardforkOptions();
    List activeHardforks = [];
    var hfs = this.hardforks();
    for (var hf in hfs) {
      if (hf['block'] == null) continue;
      if (blockNumber != null &&
          blockNumber < hf['block']) break;
      if (opts.onlySupported && !this._isSupportedHardfork(hf['name']))
        continue;

      activeHardforks.add(hf);
    }
    return activeHardforks;
  }

  /**
   * Returns the latest active hardfork name for chain or block or throws if unavailable
   * @param blockNumber up to block if provided, otherwise for the whole chain
   * @param opts Hardfork options (onlyActive unused)
   * @return Hardfork name
   */
  // activeHardfork(blockNumber?: number | null, opts?: hardforkOptions): string {
  //   opts = opts !== undefined ? opts : {}
  //   const activeHardforks = this.activeHardforks(blockNumber, opts)
  //   if (activeHardforks.length > 0) {
  //     return activeHardforks[activeHardforks.length - 1]['name']
  //   } else {
  //     throw new Error(`No (supported) active hardfork found`)
  //   }
  // }

  /**
   * Returns the hardfork change block for hardfork provided or set
   * @param hardfork Hardfork name, optional if HF set
   * @returns Block number
   */
  // hardforkBlock(hardfork?: string): number {
  //   hardfork = this._chooseHardfork(hardfork, false)
  //   return this._getHardfork(hardfork)['block']
  // }

  /**
   * True if block number provided is the hardfork (given or set) change block of the current chain
   * @param blockNumber Number of the block to check
   * @param hardfork Hardfork name, optional if HF set
   * @returns True if blockNumber is HF block
   */
  // isHardforkBlock(blockNumber: number, hardfork?: string): boolean {
  //   hardfork = this._chooseHardfork(hardfork, false)
  //   if (this.hardforkBlock(hardfork) === blockNumber) {
  //     return true
  //   } else {
  //     return false
  //   }
  // }

  /**
   * Provide the consensus type for the hardfork set or provided as param
   * @param hardfork Hardfork name, optional if hardfork set
   * @returns Consensus type (e.g. 'pow', 'poa')
   */
  // consensus(hardfork?: string): string {
  //   hardfork = this._chooseHardfork(hardfork)
  //   return this._getHardfork(hardfork)['consensus']
  // }

  /**
   * Provide the finality type for the hardfork set or provided as param
   * @param {String} hardfork Hardfork name, optional if hardfork set
   * @returns {String} Finality type (e.g. 'pos', null of no finality)
   */
  // finality(hardfork?: string): string {
  //   hardfork = this._chooseHardfork(hardfork)
  //   return this._getHardfork(hardfork)['finality']
  // }

  /**
   * Returns the Genesis parameters of current chain
   * @returns Genesis dictionary
   */
  // genesis(): any {
  //   return (<any>this._chainParams)['genesis']
  // }

  /**
   * Returns the hardforks for current chain
   * @returns {Array} Array with arrays of hardforks
   */
  List hardforks() {
    return Chain.getChain(this._chainParams)['hardforks'];
  }

  /**
   * Returns bootstrap nodes for the current chain
   * @returns {Dictionary} Dict with bootstrap nodes
   */
  // bootstrapNodes(): any {
  //   return (<any>this._chainParams)['bootstrapNodes']
  // }

  /**
   * Returns the hardfork set
   * @returns Hardfork name
   */
  // hardfork(): string | null {
  //   return this._hardfork
  // }

  /**
   * Returns the Id of current chain
   * @returns chain Id
   */
  int chainId() {
    return Chain.getChain(this._chainParams)['chainId'];
  }

  /**
   * Returns the name of current chain
   * @returns chain name (lower case)
   */
  // chainName(): string {
  //   return chainParams['names'][this.chainId()] || (<any>this._chainParams)['name']
  // }

  /**
   * Returns the Id of current network
   * @returns network Id
   */
  // networkId(): number {
  //   return (<any>this._chainParams)['networkId']
  // }
}
