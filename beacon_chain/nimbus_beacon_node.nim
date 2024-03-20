import
  std/[os, times],
  chronos,
  stew/io2,
  ./spec/datatypes/[altair, bellatrix, phase0],
  ./validators/beacon_validators,
  "."/[
    beacon_node,
    nimbus_binary_common]

from ./spec/datatypes/deneb import SignedBeaconBlock

import libp2p/protocols/pubsub/gossipsub

proc initFullNode(
    node: BeaconNode,
    getBeaconTime: GetBeaconTimeFn) {.async.} =
  node.router = new MessageRouter

  await node.addValidators()

import
  "."/spec/beaconstate,
  "."/spec/forks,
  "."/consensus_object_pools/block_pools_types

proc putBlock(
    dag: ChainDAGRef, signedBlock: ForkyTrustedSignedBeaconBlock) =
  dag.db.putBlock(signedBlock)

proc preInit(
    T: type ChainDAGRef, state: ForkedHashedBeaconState) =
  doAssert getStateField(state, slot).is_epoch,
    "Can only initialize database from epoch states"

  withState(state):
    if forkyState.data.slot == GENESIS_SLOT:
      discard get_initial_beacon_block(forkyState)
    else:
      discard forkyState.latest_block_root()

proc init*(T: type BeaconNode,
           config: BeaconNodeConf,
           metadata: Eth2NetworkMetadata): Future[BeaconNode]
          {.async.} =
  template cfg: auto = metadata.cfg

  let checkpointState = if config.finalizedCheckpointState.isSome:
    let checkpointStatePath = config.finalizedCheckpointState.get.string
    let tmp = try:
      newClone(readSszForkedHashedBeaconState(
        cfg, readAllBytes(checkpointStatePath).tryGet()))
    except CatchableError:
      quit 1

    if not getStateField(tmp[], slot).is_epoch:
      quit 1
    tmp
  else:
    nil

  var networkGenesisValidatorsRoot = metadata.bakedGenesisValidatorsRoot

  var genesisState = checkpointState
  if true:
    genesisState = if checkpointState != nil and getStateField(checkpointState[], slot) == 0:
      checkpointState
    else:
      let genesisBytes = block:
        if metadata.genesis.kind != BakedIn and config.genesisState.isSome:
          let res = io2.readAllBytes(config.genesisState.get.string)
          res.valueOr:
            quit 1
        elif metadata.hasGenesis:
          try:
            metadata.fetchGenesisBytes()
          except CatchableError:
            quit 1
        else:
          @[]

      if genesisBytes.len > 0:
        try:
          newClone readSszForkedHashedBeaconState(cfg, genesisBytes)
        except CatchableError:
          quit 1
      else:
        nil

    if genesisState == nil and checkpointState == nil:
      quit 1

    if not genesisState.isNil and not checkpointState.isNil:
      if getStateField(genesisState[], genesis_validators_root) !=
          getStateField(checkpointState[], genesis_validators_root):
        quit 1

    try:
      if not genesisState.isNil:
        networkGenesisValidatorsRoot =
          Opt.some(getStateField(genesisState[], genesis_validators_root))

      if not checkpointState.isNil:
        if genesisState.isNil or
            getStateField(checkpointState[], slot) != GENESIS_SLOT:
          ChainDAGRef.preInit(checkpointState[])
    except CatchableError:
      quit 1
  else:
    if not checkpointState.isNil:
      quit 1

  doAssert not genesisState.isNil

  let
    genesisTime = getStateField(genesisState[], genesis_time)
    beaconClock = BeaconClock.init(genesisTime).valueOr:
      quit 1

    getBeaconTime = beaconClock.getBeaconTimeFn()

  let elManager = default(ELManager)

  let
    validatorPool = new ValidatorPool

  let node = BeaconNode(
    config: config,
    attachedValidators: validatorPool,
    elManager: elManager,
    beaconClock: beaconClock,
    cfg: cfg,
    genesisState: genesisState)

  await node.initFullNode(getBeaconTime)

  node

from "."/consensus_object_pools/block_dag import BlockRef, init

func getBlockRef2(root: Eth2Digest): Opt[BlockRef] =
  let newRef = BlockRef.init(
    root,
    0.Slot)
  return ok(newRef)

proc start(node: BeaconNode) {.raises: [CatchableError].} =
  echo "foo"
  node.elManager.start()
  let
    wallTime = node.beaconClock.now()

  asyncSpawn runSlotLoop(node, wallTime)

  while true:
    poll()

when isMainModule:
  import
    confutils,
    ../beacon_chain/conf
  const
    dataDir = "./test_keymanager_api"
    nodeDataDir = dataDir / "node-0"
    nodeValidatorsDir = nodeDataDir / "validators"
    nodeSecretsDir = nodeDataDir / "secrets"

  proc startBeaconNode() {.raises: [CatchableError].} =
    #copyHalfValidators(nodeDataDir, true)
  
    let runNodeConf = try: BeaconNodeConf.load(cmdLine = @[
      "--network=" & dataDir,
      "--data-dir=" & nodeDataDir,
      "--validators-dir=" & nodeValidatorsDir,
      "--secrets-dir=" & nodeSecretsDir,
      "--no-el"])
    except Exception as exc: # TODO fix confutils exceptions
      raiseAssert exc.msg
  
    let
      metadata = loadEth2NetworkMetadata(dataDir).expect("Metadata is compatible")
      node = waitFor BeaconNode.init(runNodeConf, metadata)
  
    node.start()
  
  startBeaconNode()
