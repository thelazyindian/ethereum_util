const Map TANGERINEWHISTLE = {
  "name": "tangerineWhistle",
  "comment": "Hardfork with gas cost changes for IO-heavy operations",
  "eip": {"url": "https://eips.ethereum.org/EIPS/eip-608", "status": "Final"},
  "gasConfig": {},
  "gasPrices": {
    "sload": {"v": 200, "d": "Once per SLOAD operation"},
    "call": {
      "v": 700,
      "d": "Once per CALL operation & message call transaction"
    }
  },
  "vm": {},
  "pow": {},
  "casper": {},
  "sharding": {}
};
