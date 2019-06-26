# nim-eth2-official-tests

This repo reformats the official Ethereum 2 tests to a format suitable for [Nimbus](https://github.com/status-im/nimbus)/[nim-beacon-chain](https://github.com/status-im/nim-beacon-chain).

## Cloning the repo

Due to upstream usage of [Git LFS](https://git-lfs.github.com) to store the large test vectors,
there is an extra step after cloning the repo:

```
git clone https://github.com/status-im/nim-eth2-official-tests
cd nim-eth2-official-tests
git lfs install
git submodule update --init --recursive
```

## Usage in nim-beacon-chain

This repository is meant to be submoduled in `nim-beacon-chain/tests/official/` with the `fixtures` name.

From the nim-beacon-chain project folder:

```sh
git submodule add https://github.com/status-im/nim-eth2-official-tests ./tests/official/fixtures
```


This repository allows use to workaround the current following limitations:
  - no YAML support in [nim-serialization](https://github.com/status-im/nim-serialization) library
    which allows well-tested serialization and deserialization into and from Ethereum types.
  - [NimYAML](https://nimyaml.org) uses int by default for numerals and cannot deserialize
    18446744073709551615 (2^64-1), the FAR_FUTURE_SLOT constant.
  - Furthermore as of 0.7.1, the yaml test files includes thousands of random epochs
    in the [2^63-1 .. 2^64-1] range for the `source_epoch` and `target_epoch` field.
  - All those workarounds requires an intermediate reformatted JSON file, but the tests are huge (100k+ lines)
    and will cause review issues in the main repo.

## Commands

You can compile and run the `batch_convert.nim` file to convert the supported tests.
It needs to be run from the root of this project directory.

You can also convert individual files directly from the `fixture_utils.nim` file with the following format:
```
fixture_utils path/to/input.yam path/to/output.json
```

### Integers out-of-range of int64

Due to limitation in NimYAML library you might need to stringify big numbers like `18446744073709551615` (`2^64 - 1`) as NimYAML interprets
all numbers as `int` (`int64` on 64-bit platforms) while we need `uint64`.

#### The "easy" way

- Patch NimYAML `tojson.nim` to use parseBiggestUint instead of parseBiggestInt in the jsonFromScalar function
- Patch `json.nim` JInt to use BiggestInt

```patch
--- build/json_original.nim	2019-06-26 15:38:50.611843729 +0200
+++ build/json_patched.nim	2019-06-26 15:38:37.332013736 +0200
@@ -166,7 +166,7 @@
     of JString:
       str*: string
     of JInt:
-      num*: BiggestInt
+      num*: BiggestUInt
     of JFloat:
       fnum*: float
     of JBool:
@@ -193,8 +193,17 @@
   ## Creates a new `JInt JsonNode`.
   new(result)
   result.kind = JInt
+  result.num  = n.BiggestUint
+
+proc newJInt*(n: BiggestUInt): JsonNode =
+  ## Creates a new `JInt JsonNode`.
+  new(result)
+  result.kind = JInt
   result.num  = n

+proc add*(result: var string, x: uint64) =
+  result.add $x
+
 proc newJFloat*(n: float): JsonNode =
   ## Creates a new `JFloat JsonNode`.
   new(result)
@@ -242,7 +251,7 @@
   ##
   ## Returns ``default`` if ``n`` is not a ``JInt``, or if ``n`` is nil.
   if n.isNil or n.kind != JInt: return default
-  else: return n.num
+  else: return n.num.BiggestInt

 proc getNum*(n: JsonNode, default: BiggestInt = 0): BiggestInt {.deprecated: "use getInt or getBiggestInt instead".} =
   ## **Deprecated since v0.18.2:** use ``getInt`` or ``getBiggestInt`` instead.
@@ -309,7 +318,7 @@
   ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
   new(result)
   result.kind = JInt
-  result.num  = n
+  result.num  = n.BiggestUint

 proc `%`*(n: float): JsonNode =
   ## Generic constructor for JSON data. Creates a new `JFloat JsonNode`.
```

#### The hard way

You can use the following comment in an UNIX environment
```
sed 's/18446744073709551615/"18446744073709551615"/g' path/to/original.yaml > path/to/stringified.yaml
```

To stringify the shard and epoch fields in a generic manner
```
sed -E 's/(shard: |source_epoch: |target_epoch: |start_epoch: |end_epoch: )([[:digit:]]+)/\1"\2"/g' path/to/input/ssz_minimal_zero.yaml > path/to/stringified/ssz_minimal_zero.yaml
```

Unfortunately the `custody_bit_0_indices` and `custody_bit_1_indices` also can use out-of-range
uint64 and are trickier to find+replace. Robust solutions welcome.

Example of problematic input from `ssz_minimal_lengthy.yaml`

```yaml
- AttesterSlashing:
    value:
      attestation_1:
        custody_bit_0_indices: [6012503045711848891, 152738009429267376, 4529592720549595062,
          11642815194170551857, 8491821590750030936, 5222032322336227185, 11522761660280148694,
          7522981571797300168, 17745220427229814640, 9429048516180747443]
        custody_bit_1_indices: [13859693443699587599, 15439230562306245161, 8175380197518804189,
          12728239057041143764, 1038882316626345703, 8309514483991605157, 13367697033625567249,
          7175382025481497236, 10204780614424042841, 1013204461700977785]
        data:
          beacon_block_root: '0x3877f084318979a4eb9b4a8265af95759666fa7b23e92b9e0c483b27e5909159'
          source_epoch: 990305753157506821
          source_root: '0x9a3fd3e7388c7b2b4122c01aa81c282c89e7ab5bea4ef0196efdf23d45fafdf3'
          target_epoch: 3289939780756516146
          target_root: '0xc0a1318bab53ac3e14183f6acc62194d592c608a1a0e58f1cf1b8666a0c33bb1'
          crosslink: {shard: 6640429509854827359, start_epoch: 6921232130818454539,
            end_epoch: 17297299709635949862, parent_root: '0x09f27dfd136b00d77f67165b9229de74f7e011b52345521c73fedf3de6d1409d',
            data_root: '0x76d39883d3d95993f00dfb59df4baffb5f6c61881423f487d4b2529577e91218'}
        signature: '0x3fe2fbdefea298f3f4618547b7d62983a8c68125323915b41d391842cad5b1a6e881213399bccd897bdc3aa244becfc5629058a9c99cf00e7c421853647cf8f627d191fa2d1220383bcded690470cb6724362c97ed058f5d9b007e9a2e81fd57'
      attestation_2:
        custody_bit_0_indices: [15865561633841798824, 656318132909575419, 13360883277461675869,
          8196622609379413822, 1331970499238999554, 2887718020331875721, 2803395528730670642,
          10357423468529781350, 12859979338335994584, 2380083619101687192]
        custody_bit_1_indices: [15523197328539473637, 4191347626902666656, 14315783474977841365,
          8372626957422184648, 2744624420447080838, 10953325247775510558, 13913844002856017194,
          3574083093524379561, 273201112907762424, 4070916385268331542]
        data:
          beacon_block_root: '0xb3afe6ecbd0a6f631569ecf315b467fb4c757e1e191ffec299b63e54c5334e1b'
          source_epoch: 14895843483578530311
          source_root: '0x1a4ae894a47988ceb629277905033d2ec6511c6ed471ffda0e420fa044f5b4b7'
          target_epoch: 17709677952088965440
          target_root: '0x06a8800d18f56295d63d733c3693afd4d09a4a18bb29d4485f05174aebe88b67'
          crosslink: {shard: 15953021550022264518, start_epoch: 10604975921169076569,
            end_epoch: 8560096477656942362, parent_root: '0x3ca6025d67ad317fad6db14935f7a47296481aa9d035c94910bc75615fde6fed',
            data_root: '0xbd5975f98a9498973909377777e3a4e04013d1ed019663a0d29bd5384f1a3e2a'}
        signature: '0x90386f395b78536a76d457ff99f8878011ce5258a0b837f3d2cac604b3fe5f0ec82905466c0dd5717a29a1294e921d8b60699b1c34212e99b0abfcdc393594c2c4519c5ab79beb27b900eba74ec64f3088049aba7f6e7b687d88ae2fa2b33874'
    serialized: '0x08000000d801000030010000800100003877f084318979a4eb9b4a8265af95759666fa7b23e92b9e0c483b27e59091590597faebd545be0d9a3fd3e7388c7b2b4122c01aa81c282c89e7ab5bea4ef0196efdf23d45fafdf3322d6bbccc36a82dc0a1318bab53ac3e14183f6acc62194d592c608a1a0e58f1cf1b8666a0c33bb15f13ebea748b275c0b3474e5f3270d60267551de705a0cf009f27dfd136b00d77f67165b9229de74f7e011b52345521c73fedf3de6d1409d76d39883d3d95993f00dfb59df4baffb5f6c61881423f487d4b2529577e912183fe2fbdefea298f3f4618547b7d62983a8c68125323915b41d391842cad5b1a6e881213399bccd897bdc3aa244becfc5629058a9c99cf00e7c421853647cf8f627d191fa2d1220383bcded690470cb6724362c97ed058f5d9b007e9a2e81fd57bbe59b1aaab37053b053bb0b69a21e02b6c78d9d9458dc3e316e0e9abb9693a158eca5c4be02d975717f75caba627848d6127d08ae12e99fc8b3c98ee1ff666870df09daf5af43f6b3a4e010abb5da820f3a8657c18557c029429e57652a43d6dd04df80f9c87471d4b7303bfcc9a3b0e7bef275f6d96a0ea56f48c26553517311804b82a09983b9942a8c74ef139463599d89cde6a99e8d791487f816a00f0e3001000080010000b3afe6ecbd0a6f631569ecf315b467fb4c757e1e191ffec299b63e54c5334e1b07fa830cbaaab8ce1a4ae894a47988ceb629277905033d2ec6511c6ed471ffda0e420fa044f5b4b74081d47c446ac5f506a8800d18f56295d63d733c3693afd4d09a4a18bb29d4485f05174aebe88b67c6863ab7938464dd5991daa869712c931a87d0a16492cb763ca6025d67ad317fad6db14935f7a47296481aa9d035c94910bc75615fde6fedbd5975f98a9498973909377777e3a4e04013d1ed019663a0d29bd5384f1a3e2a90386f395b78536a76d457ff99f8878011ce5258a0b837f3d2cac604b3fe5f0ec82905466c0dd5717a29a1294e921d8b60699b1c34212e99b0abfcdc393594c2c4519c5ab79beb27b900eba74ec64f3088049aba7f6e7b687d88ae2fa2b33874a8de34233fcc2ddcfb0cb953ddb51b095d5f8f468d646bb93ecffeedd540c07102b670aa1c1c7c12892d605d3d3c132832f6e85e61a9e726660a03c6c4f5bc8fd84261b812d377b2983d48fc70c10721e556e391b9796dd7a0bdb5bf75a82a3ad52076e338e1abc6c8480292db8b317486519c665edd16261e10fa96470702982a9d6ee266e717c1a9f73f23a3b19931f8ca1bf7f69aca0316743c3ee2cc7e38'
    root: '0x3c401177660e734aeb8321185db36d6dfc4ac45fc65449c32c67b5a69c0f3eea'
```
