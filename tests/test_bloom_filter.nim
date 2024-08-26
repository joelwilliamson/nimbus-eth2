# beacon_chain
# Copyright (c) 2024 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}
{.used.}

import ".."/beacon_chain/spec/crypto, unittest2

from std/sequtils import mapIt
from ".."/beacon_chain/bloomfilter import
  constructBloomFilter, incl, mightContain
from ".."/beacon_chain/spec/datatypes/base import
  HashedValidatorPubKey, HashedValidatorPubKeyItem, Validator, fromHex, pubkey
from ".."/beacon_chain/spec/eth2_merkleization import hash_tree_root

let pubkeys = [ 
  ValidatorPubKey.fromHex("0xd52edb450c9fdad41ce16d724be7b986a5422f8a791b68a370ef86045a85147cf8f7a6342034958d46a136965b622c48"),
  ValidatorPubKey.fromHex("0x6f343f3c55183fc6c980e7597ac47c14b59322e22be9109e7ad8412f5b0e5c918b4e6dd60e5b98eb8d2501a94b2fb022"),
  ValidatorPubKey.fromHex("0x5e40d512d91a27aa60e95fa10acb60a8a5dc6d85f2238e6418bfd4ebf44215270301f9e15564dde2c2b628fe80e7f970"),
  ValidatorPubKey.fromHex("0x4ae23aea68bfd30022d4efdde1b4428f23317a70fb6df716dc16ccde96b74174c2f8cd18237bdb7ae900acbaba8cad70"),
  ValidatorPubKey.fromHex("0x032fc41fa7fc1a44a1f38d73a3465974c2048bb347a9fcb261b93fc6581009d7c9870f0e1a21d619069d5250456cd5ca"),
  ValidatorPubKey.fromHex("0x8cea40c0986bc0dc51b664e846a08948112987903b6ffe462b77f092dc43e752dfefaad738810c43364b2f2ed24a5988"),
  ValidatorPubKey.fromHex("0xc663a799c732d544a835251935fc5be18eb365806279863877ff2f9308779106816a48be235b4b5d9dcaf42bdf1119f7"),
  ValidatorPubKey.fromHex("0xc5682345f202d59614089a6fd5c2375adf8e40316bb69114474f1861c9a6791cc512c0133860353a4bb35d659f3fcd14"),
  ValidatorPubKey.fromHex("0x593c3b4d962ff759945f70afa98d3d653fb4c73a2808a4f30472d972cdfd12df7535ba5ba88f3c5e8a59ff844129949f"),
  ValidatorPubKey.fromHex("0xabc272512d7a861c0bc190c23cdef8d4d6b9b159d9f53aaf8834c8f521edf416b850d6c14b4c040bac7ceaa1be117e98"),
  ValidatorPubKey.fromHex("0xd6dc377e866b762ab63dc2155be71bf24624855e255332dc48a175a9024e71057ad4ad351d7b5aeee944afaaff5d4e1b"),
  ValidatorPubKey.fromHex("0x9af21f5d70846185023f70f7841f2f6323c27307c3e54025f103ba359c856b76d3c06f0a09b4669e4838187805253467"),
  ValidatorPubKey.fromHex("0x92312221300b0707c401d3163f951babaeb4121fa7222dafebba8b8cf91928567477b4b2c249af446a759ef13d990a0c"),
  ValidatorPubKey.fromHex("0x37c2731f409eafdb4bb5a1722e33cc39ab8dcf87eb7b4702aca0dcfdceea15002c1b697124eb6f1f83bd807cafb0ff43"),
  ValidatorPubKey.fromHex("0xac72cfe3b2a0c549f608746fd0c3daa7195c42e05157f8d8b10bd84b1d04bff763eb6bf74620be8bcdba0ea4704630ee"),
  ValidatorPubKey.fromHex("0x6cab2ab1fd15489aae21becc2cfb8923513bacce9d9773c3ad35ef7535a6e92d3a78de4d103e2ed88a818f872de331f2"),
  ValidatorPubKey.fromHex("0x99138fe703da75af5571e3994e7c0b6bba06cb2a4a4978e4b41e52e06af7c1c928105bb5fae878d16934529c96883e97"),
  ValidatorPubKey.fromHex("0x850c61b9bf24be2470fe0b1ead466d9b93ea4b4d41980f2f6c82eef9b526d68bf6be613b4e7653b79267829a4107dd30"),
  ValidatorPubKey.fromHex("0x310ddff78f82b2ea039f6077b099f4e8e148da97d35a14140cdf5754db933034d15a58085ff91522e2722504a6ebdc87"),
  ValidatorPubKey.fromHex("0x331103905b6cc0da6ef1fc2e10cb6c9feed110a5a09fed5f32f56416ea814e80961fdf81455a6483de18c40e1f3bb718"),
  ValidatorPubKey.fromHex("0x8f4a32c968cb197581a3c4cec214d33736026997d1a4dc9538c932b3d859dd0547a7a06a08a9115c2c2a4fdfccaa07d2"),
  ValidatorPubKey.fromHex("0xda87a0a9a300057c1f4a196f9e8947a1f461aca3be84799ac9a187c4ecb0f6450cc15e64d30b30da4f5cf2848808b9ab"),
  ValidatorPubKey.fromHex("0x91e197089e1a351f0f6b1d4777c464edffac62067162133c01185074d520cbefd4e661d978cf04f9832804cb636e7a5f"),
  ValidatorPubKey.fromHex("0xf0e76be22bf4afd4ea3730ef7dd0156b777e2835d828deee887881263affa33bf4685ad18fa05d09e87481a4c89c345c"),
  ValidatorPubKey.fromHex("0x4a0276deca3b176cd6fe0b648f0fc418568c0c9d29d607e74e02c17852b72e636e681f4be63b0b1ad842db3efe0518c2"),
  ValidatorPubKey.fromHex("0x7ad942fe106ee88c214bd5e34078b2c98849ba594a4e266a8548c1b5e44bd151135fa5a720323927c142af19fd1e74b1"),
  ValidatorPubKey.fromHex("0x0648a3a4f9cf10e8f8881902549e0b7c6b207e72d5498e54503e1497ccfc03954a7440dfa0cd5ba62f80234bd99733ca"),
  ValidatorPubKey.fromHex("0x5d569974f21599857609ec27e11cd2b9c007209790fe36e0cc5ff1bef0c83c07eddc84602ae04a3b803b158fa8d8a7df"),
  ValidatorPubKey.fromHex("0x63290edbc38bfa204b7fd4b3fba3f677f00a54897b4c62c83ff5a1d0a905f64d2ea73ab9fa903d86c3ac8e5c91f66cc2"),
  ValidatorPubKey.fromHex("0xc56363e2f8a19dcb1c9fa0b446b9c2e6a93218250df814da9566c4ceaeb116a4d60031ec60b89c23e0e911dccc301e34"),
  ValidatorPubKey.fromHex("0x68c143f8c1cf0dc47345526bfd5123ed31edcbf393673352fe948107f5317ddcf8934814657879da7a1ec5782d13fdc4"),
  ValidatorPubKey.fromHex("0x6e1c7d1ca0056d721a94cda0a776b68d447b1706882e04ed7ca7356d61d7d08c9c2aaf782e9c3f0c4c6e4758ca6c9228"),
  ValidatorPubKey.fromHex("0x12d410ee83662b4506546e912ada2e0273f27279fdc46565d0c862e262bdbe98f91466a5bfa4e65660fd8e5a4da28543"),
  ValidatorPubKey.fromHex("0x039b3ebfcc2d6f181b40da2b63d94406c440f2c32547e69560bb137a295886c3e82b7ac5aa18e14bfe080b805ae75197"),
  ValidatorPubKey.fromHex("0x02875a3d83a806329b612096329959eec1a2300d9740a2c94d030dc5c99c6c0c62bd5f832b615d36cc165bc304e7a892"),
  ValidatorPubKey.fromHex("0xfc0acd4ca1e1ea234b39219af5c899a743332e33a17be2dcb10bfed72e4d437fd2693ac1ae1dcec2d189a9689b0b53ff"),
  ValidatorPubKey.fromHex("0x8104b3b199bf0261b1584fe269e5599266bd60cbd201205565e139fbe4a9577f48f71cebae7f7cf434cf07f66cc51ec9"),
  ValidatorPubKey.fromHex("0xcfe998a8989f5318aee192e185e87a51b96aeec479d37f00cdcfafe534f514c316a10c4ba311c076cae6b192386dc25a"),
  ValidatorPubKey.fromHex("0x44d7bcaebb2da8001982540c8917da5ff950750d90e5b788f2c35262b58efca64dfe3df46793380016a9d24b521c3920"),
  ValidatorPubKey.fromHex("0x2b7fd53635b1effa086d6db933b65bfbca85160ed731fa8b5c77a8b726b4c5b61ff56d88d57f3e4fece8c593df18f2b3"),
  ValidatorPubKey.fromHex("0x642e56b532e08e4cb75d619ed3b360ad1971584e338638b7d5716672922e513465c3fb13d26d381e7b21ffe9bc8e428f"),
  ValidatorPubKey.fromHex("0x61820ec30590c9e75b06b0cc454686067fc6db1d329814aaf1a31e3e3defe50f41ee15c106e3602c4931e131032787db"),
  ValidatorPubKey.fromHex("0xdc41f2c1504c90f44ba32b7e9d8e069d9c788a125f45df163c65c56cf22f5823e7614b2fcd5cec7c14a276b67e0fa7b8"),
  ValidatorPubKey.fromHex("0x079d59adc0ac14e2c7397a23c3debcb080d1378ad4ac6a091daeb12f1d134c063ce4629bdf0880172017b81bed0064ec"),
  ValidatorPubKey.fromHex("0x41e0b5b8befce0add67f48a9b485307105e3772aae012777c6afa62304f67a7407dd0c16b791754076549eba2b7a18a8"),
  ValidatorPubKey.fromHex("0xd36e7623ae93544eaa5868e50936797bddffb2b3b66728b38f0c479f1640c60e82ad887b960e6c9340526da8a030f5b2"),
  ValidatorPubKey.fromHex("0x8986816ba54e777b2c6045a805b11c08bb1f64898a6786428da9efc2ae466cb940fa3c11feacfdeeba87df9b3ce3e93f"),
  ValidatorPubKey.fromHex("0x5ea844f61fe1710c19cb67e5daec1c3ba0fc203ab23598b1c9cfae6f4ab9d9f127d50d0b9cebf64d7650f66c06ca5596"),
  ValidatorPubKey.fromHex("0x3e77eef77d7573362dffd75800d7554ad41f4349b3a2ab72d6fe031bf3c42bf283f985b933ac142de581079371018fdc"),
  ValidatorPubKey.fromHex("0xa848afaf6d44d43e2f072bf3cf82e1ae6a8c63cda627c12d95a43e6ac4f20b8a9213a723d642c95ae2bd66bccadb8467"),
  ValidatorPubKey.fromHex("0xb0b1b8582a84cbc5f43585c9d2e2b9d34f0788977f5004d6e21b12bfd5cd7165d72fba0da182f13aa44af63f9045da3e"),
  ValidatorPubKey.fromHex("0x4f5517fe02d94b1eeee0a294b4f7d6064f8a3eb3fd6f31801ab7545be1dc290f26972515b23018b23efa9a812f648b6b"),
  ValidatorPubKey.fromHex("0xa0f040547549deccd5cdc3a0a3a91974754fdc8177763adfc25ffb7704f8ca5e83985db3f276fadb1c113fb279720a05"),
  ValidatorPubKey.fromHex("0x7dd6ae00b240244b0e49cf7538a5021e6725d3b87b909e797c7d9c6947c3b29353ff61c128ad36db66b77f197308ba04"),
  ValidatorPubKey.fromHex("0xdc824ba613c5ddf2c112f0ca3bb91e6d7bfcbfd340b1e611183b8bf8c4cc37d1b843909f2c9db8353de6938834516fa2"),
  ValidatorPubKey.fromHex("0xb085822d9549b0b674591015525f0846ec00ef3ff52b1107592285d0a75b757708a54fcfe5655f28473c33ae4d43ee5c"),
  ValidatorPubKey.fromHex("0xab704b4be6cbbbe0f9176fd3dccbf2c0272e4f42538d5f4844a288820179f7c799d051c501e78ee3848484e1818d8456"),
  ValidatorPubKey.fromHex("0x12c3c3fa284bd55ebbe82abce576c104929a909e9d78eba2f595ce42822ffe52c427ad61923f48107b1639e4bd99a45b"),
  ValidatorPubKey.fromHex("0x64c86e12cdc8091c0b0e317abc073a71c96df04e1fb2235219a1289d3ce62b323fc1a226f0b298ee5596bbebabdacaf5"),
  ValidatorPubKey.fromHex("0x1d5cc7e50da341a6f6931dc9fb4df6a37d21545281b9fdc2836182e2f45ff2a2a6e9181ab5d4893125fea6495fe68dd3"),
  ValidatorPubKey.fromHex("0x923573206c1b1a75716339eb61f489b10d5811a280dd15333f980374ca63664741e16d911f8372ff74714ec79662683f"),
  ValidatorPubKey.fromHex("0x7c1fe9a7ab8da368228a27f575cbb36aa9ce2e68d60c336184f02b985b5c13a7d09cbe315895a1da5f1f86d713f94417"),
  ValidatorPubKey.fromHex("0xbb85e9cdac2db9a2dda61480082f3ed0f683db798219cdbfadac846c7b374f90a8c6784c95b53676b631152077619ee5"),
  ValidatorPubKey.fromHex("0x58db99741e4c904ec1444a9c23c287eeea88de3c647c9dd9ed45e8230b7ed0bf080d546ae4597af148b69809df07e73c"),
  ValidatorPubKey.fromHex("0x2208988a10feef0f7ec1550e8ef8c14c786de0bd647e5b3d10d3b884c8521af0ce59ba1a8583afe888b9348d2e1ed7d5"),
  ValidatorPubKey.fromHex("0xd11cd69262896cf2a19a52928b7fcba8cd1c1661d0c938ffbfb4482283f53b44435af5695ce10fddc9315393aeda57ef"),
  ValidatorPubKey.fromHex("0x4a568216203673c3f895529c194c2ca172d613e8f866dd9ee5e8db9b5b681942c7b5634c2349689a6753e1d1113d062e"),
  ValidatorPubKey.fromHex("0x7ceb8add4aebaf802c3e8b37f85076a6de8c6d7007dcb92fa7b4da028a571f9dae41338b8d3f2446db4335ffbff7f083"),
  ValidatorPubKey.fromHex("0xfda68482093ff5780855a139008ba695a1bd74864cb4ff72451caa5a46f8db497b44baecc93ead6aacd34c9ac92522d4"),
  ValidatorPubKey.fromHex("0x8483c152bf17da7df9f3e7102d2fdd143b7649a95920263c8231ce6e80f01a849ae62064f2d03d6dcb89024d07ef9f33"),
  ValidatorPubKey.fromHex("0x33ea02799800edf1c7660f1acf923f33913f2eaa89944c3b8ca4e44a2d061a1c6e4286ca92251bc0f3b11c535824aa0e"),
  ValidatorPubKey.fromHex("0x46e3fdc0b5b6df3147a95ccfdfe66373bdbf96e6d5eed7306428f986778dd3b9eecb0bc5e568213b0b3faee7ce6caa79"),
  ValidatorPubKey.fromHex("0xac9df2f76111be4c822a91d24a85291f55ed4ae4c574803781018360f83cc395fee9a3e56d92fc34d2f74f4dcd81c19d"),
  ValidatorPubKey.fromHex("0xe6724c500b1573fee191980bdf4d8e30086bc2f2460ac775d9ceec553d4870f314fae83d04b9d9f17dc1bec64e1b5260"),
  ValidatorPubKey.fromHex("0xb45d08842d2721b18d17209081b5b95ed2b9198c0dd47d16117834e1b96913071f5afe5abe53206a10103baeadbc4314"),
  ValidatorPubKey.fromHex("0x8badb39dec9b9c348e4833797ac1f7fc84f7bac557d1bed58096144f48b8cda5fd8ddbe21e278f0b6d5c9aed6c90f783"),
  ValidatorPubKey.fromHex("0x5fd79ebdc6f58defee05a823c9d793dfdc4b0c43ddbd1eb74c3432f59d069fe026ead5b1c925626ed9f915aee6f91247"),
  ValidatorPubKey.fromHex("0x7763334ab10953dea5bffac69dea12eb53f0cd46947f04334d417223040453cfbe0f658d6f1e22a79c09807bdf3ee2c1"),
  ValidatorPubKey.fromHex("0xf2df734e8b11d562900079828c2cde7dca86a2d63cf57813c67bab47fc627f1bb773d70015a486a1a2cd09b4a04c1b28"),
  ValidatorPubKey.fromHex("0xd0c621f5bb524fb68aa3631b4a0629bf6bc210fe30e237d9caf8bfb476686b82eb8e8460062d187d6e2699ddc8988c0c"),
  ValidatorPubKey.fromHex("0x10eb53f3ba6d355e301c785a2f204294c6a63233edee9cc135791815d086c9a8604c0d46baca6abe8c7a58e708e2106a"),
  ValidatorPubKey.fromHex("0x4244a5380986232f8fb39f9396be04e6c504c3b1f87e9672d7154d09b97f0fa86cae849aac06b30ce993e00e126cf5b0"),
  ValidatorPubKey.fromHex("0x2382850a411c389df2afdd2a03a6196b451893e2674d11e0b8ac6914ffa53c7a1ced201cc1390a3aa1a2879dcdfa143b"),
  ValidatorPubKey.fromHex("0xa20189e31ecc6a8c2002a9dec9645aada8f01dbaa6f22f7efcc10e1de109f2528edcbe768f1baf78b8ecba189d70e28b"),
  ValidatorPubKey.fromHex("0xd1f4e4ebedcc39544148157f4a5279def61a8dda08c087afbcc85e85f5fe8a244972e26077cfc1820c0c85814adfad6e"),
  ValidatorPubKey.fromHex("0xf62d8f1b982babdffcc6616f8b2ac54fac5224c7a1fb66121079b9a521aff4f2ade3cd7aa40baa838e522a927179ac82"),
  ValidatorPubKey.fromHex("0x7e0c87bbf88d5762dfca69732bb36525d11a755fde736f28088bc17958cb8d5745a923a56c6c0b4e98c0ffd9623f9816"),
  ValidatorPubKey.fromHex("0xbf1d6ae7fd84bee92a4e22bd73b3869402504736ff5af0da6e02181ae2506a248ca4e969a82ea0304a93b6bb68d29435"),
  ValidatorPubKey.fromHex("0x8ec4826fcde422ba62d222274fda595cd988d27fa0ffcbc91ab7ace22d2c9617a94ba008064a5f159801dc3b1956d96f"),
  ValidatorPubKey.fromHex("0x068bee5a0d17f286962fdf71fe6e9d8b2d05f8203ecf2fbc0672003ec18a53636062dabd430715b8599f1111091417dd"),
  ValidatorPubKey.fromHex("0xc0e15eadc90fbf93e2deccdd58cb13b30fea11913ca39c2ee42ddf74201dae1e84553ce8c6818d91658cb8ae97573c24"),
  ValidatorPubKey.fromHex("0x5a0e0446883b0a0f09ea42faffc02ebf25407159503f5b430a216a54b1b9a4272765314c267ee2f3be8fe101208a28fd"),
  ValidatorPubKey.fromHex("0xc22aa9c85a08126c371c19163c940c459a478a7391cabfb170a352faa30687ef571568d4ad327a6fe69652cd0daa33af"),
  ValidatorPubKey.fromHex("0xc53c961a6977d4711914b2852ac231e6dae019ce13555e189bcae94b1786f0bb3b3e8ad173c3f029758ecbc0c0b1c6f0"),
  ValidatorPubKey.fromHex("0x925aefdfeaeea3402ddd678a7069c20183fed9a11f7f866215788177ba9ae9d2914874866c2dd78f79f81495ce172352"),
  ValidatorPubKey.fromHex("0x4aca00821c817196db75be87cb044f36466c65e5ea3ca90c60353b3927107bdbd8ec0775dfe8c08ea123801f4443d01b"),
  ValidatorPubKey.fromHex("0xb84960b4042210498cd2ab478685a1b65e2a4e3bbf2e813440e38f38659def0e5ebe9514316f125634e23ae398fa2458"),
  ValidatorPubKey.fromHex("0x3dbee79b334a30be85c82ae64331ab0bd7ce371c2b5cc734212f079209a845d0f45393bbca97ffad203e0af81af4325b"),
  ValidatorPubKey.fromHex("0xfd9e33dec3e8ebeeb2ec64297ace2997dc6ecf148d98067cc3aabf2419a2788160c4d670836419672eebd663999ba53b"),
  ValidatorPubKey.fromHex("0xdd9de04d992ecd5991ed84567803f2195b9c0cbbf74968e60c2272ba59f741fb07e84eefd970a0507b36ad7e4bd56e7e")]

suite "ValidatorPubKey Bloom filter":
  test "one-shot construction with no false positives/negatives":
    var hashedPubkeyItems = mapIt(pubkeys, HashedValidatorPubKeyItem(
      key: it.get, root: hash_tree_root(it.get)))
    let
      hashedPubkeys = mapIt(hashedPubkeyItems, HashedValidatorPubKey(
        value: unsafeAddr it))
      validators = mapIt(hashedPubkeys, Validator(pubkeyData: it))

    let bloomFilter = constructBloomFilter(
      validators.toOpenArray(0, validators.len div 2))
    for validator in validators.toOpenArray(0, validators.len div 2):
      check: bloomFilter[].mightContain(validator.pubkey)
    for validator in validators.toOpenArray(
        validators.len div 2 + 1, validators.len - 1):
      check: not bloomFilter[].mightContain(validator.pubkey)

  test "incremental construction with no false positives/negatives":
    let bloomFilter = constructBloomFilter([])
    for pubkey in pubkeys.toOpenArray(0, pubkeys.len div 2):
      incl(bloomFilter[], pubkey.get)

    for pubkey in pubkeys.toOpenArray(0, pubkeys.len div 2):
      check: bloomFilter[].mightContain(pubkey.get)
    for pubkey in pubkeys.toOpenArray(pubkeys.len div 2 + 1, pubkeys.len - 1):
      check: not bloomFilter[].mightContain(pubkey.get)