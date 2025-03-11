# \[Changelog\]

## Unreleased

### Features

- (x/liquiditypool) [#729](https://github.com/Switcheo/carbon/pull/729) Swap feature to allow direct swap of tokens against liquiditypools.

## V2.65.0 - 2025-03-13

## Features

- (x/order) [#1084](https://github.com/Switcheo/carbon/pull/1084) Order delay for perpetual markets to prevent market arbitrage.
- (x/oracle) [#1117](https://github.com/Switcheo/carbon/pull/1117) Historical oracle results collection for volatility index analysis.

## Improvements

- (x/broken) [#1116](https://github.com/Switcheo/carbon/pull/1116) Compress order books event size and reduce number of event emission.
- (x/market) [#1118](https://www.notion.so/Sprint-256-19d3f49505a4804b9310ee00bd1b0449?pvs=21) Addition of market `creator` field to help better identify user created markets and unverified markets.
- (x/coin) [#1120](https://github.com/Switcheo/carbon/pull/1120) Addition of `is_deprecated` field for tokens that are in final state.
- (x/coin) [#1124](https://github.com/Switcheo/carbon/pull/1124) Changed naming and symbol prefixes to align with Demex.

## Bug Fixes

- (x/market) [#1119](https://github.com/Switcheo/carbon/pull/1119) Reset settlement counter for settled markets and settlement price for perpetual markets.

## V2.64.0 - 2025-02-13

## Features

- (baseapp) [#1106](https://github.com/Switcheo/carbon/pull/1106) Bump Carbon Testnet Chain Id to "carbon-testnet-42071".
- (x/market) [#1073](https://github.com/Switcheo/carbon/pull/1073) Pause market trading when market index prices is stale for more than the allowed duration.
- (x/market) [#1112](https://github.com/Switcheo/carbon/pull/1112) One step message to create new perpetual market with oracle and perpetual token.

## Bug Fixes

- (x/cdp) [#1108](https://github.com/Switcheo/carbon/pull/1108) Clear deprecated CDP reward schemes and account debt that have been claimed during Polynetwork migration.
- (x/pricing) [#1109](https://github.com/Switcheo/carbon/pull/1109) Reset market settlement count for perpetual markets which should not be settled.
- (x/cdp) [#1111](https://github.com/Switcheo/carbon/pull/1111) Migrate stuck user funds that has been manually refunded to the user.
- (x/order) [#1115](https://github.com/Switcheo/carbon/pull/1115) Fix bug where virtual orders retreivale was not keyed with delimiter resulting in possible key collision.

## V2.63.0 - 2025-01-27

## Features

- (x/order) [#1012](https://github.com/Switcheo/carbon/pull/1012) Best order flag for users to chase best orderbook prices for maker orders.

## Improvements

- (x/market) [#1013](https://github.com/Switcheo/carbon/pull/1013) Addition of settled market store for finalized markets and optimize searches through markets in Broker processes.
- (x/broker) [#1099](https://github.com/Switcheo/carbon/pull/1099) Remove blacklist token functionality.
- (x/coin) [#1104](https://github.com/Switcheo/carbon/pull/1104) Add method for creation of native Perpetual tokens.

## Persistence

- (db/archiver) [#1103](https://github.com/Switcheo/carbon/pull/1103) Fix dangling archived closed position from showing incomplete position information on websocket.

## V2.62.0 - 2025-01-14

## Features

- (x/perpspool) [#1032](https://github.com/Switcheo/carbon/pull/1032) Commission system for fees and profit for Perpetual Liquidity Pools.
- (x/position) [#1086](https://github.com/Switcheo/carbon/pull/1086) Negative allocated margin system to deduct funding rates from positions with insufficient margin.
- (x/bridge) [#1094](https://github.com/Switcheo/carbon/pull/1094) Automatic withdrawal from group for withdrawing grouped token to external chains. Remove additional encoding for withdraw and execute.

## Improvements

- (x/pricing) [#1047](https://github.com/Switcheo/carbon/pull/1047) Reduce number of pricing update events.
- (x/pricing) [#1080](https://github.com/Switcheo/carbon/pull/1080) Allow future price update for token prices.
- (x/bridge) [#1095](https://github.com/Switcheo/carbon/pull/1095) Additional validation to prevent withdrawal of zero amount.

## V2.61.0 - 2024-12-31

### Features

- (x/lockproxy) [#1092](https://github.com/Switcheo/carbon/pull/1092) Add messages and methods to add and remove extensions to the lockproxy contracts.

### Improvements

- (client/grpc) [#1051](https://github.com/Switcheo/carbon/pull/1051) Add a hard limit of maximum 1000 results for GRPC queries.
- (api/ws) [#1076](https://github.com/Switcheo/carbon/pull/1076) Fix duplicated websocket loading of states and connections to node.
- (x/cdp) [#1079](https://github.com/Switcheo/carbon/pull/1079) Refactor method logic for updating rate strategy.
- (baseapp) [#1085](https://github.com/Switcheo/carbon/pull/1085) Add new check to ensure proper intialization of module accounts.

### Bug Fixes

- (x/broker) [#895](https://github.com/Switcheo/carbon/pull/895) Fix bug where reduce-only orders cause incorrect adjustments to existing worse non-reduce-only orders.

## V2.60.0 - 2024-12-26

[#1088](https://github.com/Switcheo/carbon/pull/1088) This upgrade will migrate all Polynetwork tokens to the new Axelar tokens.

## V2.59.0 - 2024-12-22

## Improvements

- (x/bridge) [#1089](https://github.com/Switcheo/carbon/pull/1089) Addition of AxelarBridgeCallDenom into parameter store as Axelar requires the sending of Axelar registered tokens during the IBC transfer of GMP messages.

## V2.58.0 - 2024-12-19

[#1082](https://github.com/Switcheo/carbon/pull/1082) This upgrade focuses on the deprecation of Zilliqa related liquidity pools and markets. The denoms affected are:

axt.1.18.a67f22
dxcad.1.18.9dfb98
fees.1.18.c061fe
gzil.1.18.c11154
huny.1.18.3a5a8b
lunr.1.18.fa4af7
play.1.18.3cf025
port.1.18.b2261e
xsgd.1.18.be52cd
zil.1.18.1a4a06
zusdt.1.18.1cbca1
zwap.1.18.393529

## V2.57.0 - 2024-12-17

The purpose of this upgrade is to test additional features to the Polynetwork token migration.
This upgrade will migrate two tokens from the Polynetwork token to the new Axelar tokens. Below are the tokens that will be migrated and their new denominations:
bnb.1.6.773edb -> brdg/1768794901f8a19c2ec795a5402653cef6cbfe6b3ec6398d39fc37de963cb667
usdc.1.17.851a3a -> brdg/d8c3db91ad4ba11fe52971b4c387b0110c8951ec0f5b8f0fb445ef0306a349e1

## Improvements

- (baseapp) [#1078](https://github.com/Switcheo/carbon/pull/1078) Replace all CLI to broadcast transactions using From or Group address when available.

## Bug Fixes

- (services/oracle) [#1074](https://github.com/Switcheo/carbon/pull/1074) Fix oracle service blocking data processing pipeline during long downtime
- (api/ws) [#1077](https://github.com/Switcheo/carbon/pull/1077) Fix read/write lock for websocket services.

## V2.56.0 - 2024-12-4

This upgrade will migrate four tokens from the Polynetwork token to the new Axelar tokens. Below are the tokens that will be migrated and their new denominations:
nex.1.17.59c1ba -> brdg/0b02ac3efc9df2e80d00f141133c180cdaee0122f92d3e2e310f704e82425a18
gmx.1.19.70275d -> brdg/0f18019978979327ad0ecca00adba941ebf8828f40af270f5e2a3a94c3802d72
wbnb.1.6.ad598c -> brdg/1768794901f8a19c2ec795a5402653cef6cbfe6b3ec6398d39fc37de963cb667
blur.1.2.0c0069 -> brdg/a8bbd91ae3dda9de2e50926a0d93be4d0d5cea34f3080014e5c0c0db6eaf61a4

## Improvements

- (x/bridge) [#1061](https://github.com/Switcheo/carbon/pull/1071) Improve poly migration token generation script

## V2.55.0 - 2024-12-2

This upgrade will migrate four tokens from the Polynetwork token to the new Axelar tokens. Below are the tokens that will be migrated and their new denominations:
nex.1.17.59c1ba -> brdg/0b02ac3efc9df2e80d00f141133c180cdaee0122f92d3e2e310f704e82425a18
gmx.1.19.70275d -> brdg/0f18019978979327ad0ecca00adba941ebf8828f40af270f5e2a3a94c3802d72
wbnb.1.6.ad598c -> brdg/1768794901f8a19c2ec795a5402653cef6cbfe6b3ec6398d39fc37de963cb667
blur.1.2.0c0069 -> brdg/a8bbd91ae3dda9de2e50926a0d93be4d0d5cea34f3080014e5c0c0db6eaf61a4

## Features

- (baseapp) [#1016](https://github.com/Switcheo/carbon/pull/1016) Polynetwork to Axelar migration code for the conversion of old Polynetwork-Bridged denominations to new Axelar-Bridged denominations. This feature includes the functionality to perform an Administrative Withdrawal of funds in the external LockProxy contract to a MutliSig EOA wallet (0x69CfA6d0F45C02aE6a24Db4A214013d0de4c6016) to assist with the transfer of fund to the new AxelarCarbonGateway contract.
- (x/bridge) [#1046](https://github.com/Switcheo/carbon/pull/1046) Add destination address encoding validation based on connection encoding type.
- (x/coin) [#1057](https://github.com/Switcheo/carbon/pull/1057) Add active status filtering to coin tokens GRPC query.

## Improvements

- (api/ws) [#1054](https://github.com/Switcheo/carbon/pull/1054) Optimize websocket services load by reducing the number of unmarshalling of udpates.
- (x/bridge) [#1062](https://github.com/Switcheo/carbon/pull/1062) Enforce lower cased EVM addresses for bridge token denominations and external mappings.

## Bug Fixes

- (services/oracle) [#1061](https://github.com/Switcheo/carbon/pull/1061) Fix dereference of nil pointer in oracle service error handling.

## V2.54.0 - 2024-10-30

## Bug Fixes

- (x/broker) [#1049](https://github.com/Switcheo/carbon/pull/1049) Fix memstore in virtual orders causing app hash mismatch

## V2.53.0 - 2024-10-17

## Bug Fixes

- (x/liquidation) [#1045](https://github.com/Switcheo/carbon/pull/1045) Fix possible chain panic

## V2.52.0 - 2024-10-16

## Features

- (x/insurance) [#977](https://github.com/Switcheo/carbon/pull/977) Limit the maximum usage of insurance fund by each market within a interval period to prevent insurance fund draining.
- (baseapp) [#1037](https://github.com/Switcheo/carbon/pull/1037) Override `config/config.json` with recommended values through `carbond start`. Allows gradual tweaking of configs on behalf of validators through software upgrades to improve block time and liveliness.

## Improvements

- (app) [#981](https://github.com/Switcheo/carbon/pull/981) Refactor keepers in `app.go` as pointers to reduce the need to order keeper initialisations.
- (services/oracle) [#1041](https://github.com/Switcheo/carbon/pull/1041) Improve oracle responsiveness and accuracy.

## V2.51.1 - 2024-10-1

## Bug Fixes

- (baseapp) [#1038](https://github.com/Switcheo/carbon/pull/1038) Reordering oracle processes to run after pre-blocker to ensure migrations are completed first.

## V2.51.0 - 2024-09-30

## Features

- (x/otc) [#951](https://github.com/Switcheo/carbon/pull/951) Over The Counter (OTC) module for the OTC trading and dust conversion for users and distribution keeper.
- (baseapp) [#966](https://github.com/Switcheo/carbon/pull/966) Allow users to sign Carbon transactions without switching wallet network by enabling cross-chain signature verification for EIP712 signature.

## Improvements

- (x/oracle) [#991](https://github.com/Switcheo/carbon/pull/991) Change handling of oracle data to round using significant figures.
- (x/subaccount) [#998](https://github.com/Switcheo/carbon/pull/998) Refactor key of subaccount store for better iteration for oracle delegates.
- (x/cdp) [#1000](https://github.com/Switcheo/carbon/pull/1000) Refactor of CDP methods with additional validation.
- (x/cdp) [#1027](https://github.com/Switcheo/carbon/pull/1027) Addition of token name to CDP asset params query.

## V2.50.0 - 2024-09-23

## Features

- (x/bridge) [#754](https://github.com/Switcheo/carbon/pull/654) `Bridge` module integrating General Message Passing for cross-chain communication. Integration of [Axelar](https://axelar.network/) as a bridge to Carbon.

## V2.49.2 - 2024-09-12

## Persistence

- (db/cdp) [#1011](https://github.com/Switcheo/carbon/pull/1011) Archiver to delete extraneous position updates to improve persistence position query speed.

## V2.49.1 - 2024-09-09

## Persistence

- (db/cdp) [#1007](https://github.com/Switcheo/carbon/pull/1007) Fix CDP positions all query incorrect filtering causing unpredictable number of rows returned.
- (db/postions) [#1008](https://github.com/Switcheo/carbon/pull/1008) Fix positions all query using the incorrect pagination causing null return.

## V2.49.0 - 2024-09-09

## Improvements

- (x/oracle) [#995](https://github.com/Switcheo/carbon/pull/995) Remove unused oracle vote and marks related code.

## Bug Fixes

- (baseapp) [#1004](https://github.com/Switcheo/carbon/pull/1004) Fix [MetaMask signing issue](https://github.com/MetaMask/metamask-extension/issues/26980).

## V2.48.0 - 2024-09-04

## Improvements

- (x/market) [#992](https://github.com/Switcheo/carbon/pull/992) Refactor of market validations for newly created markets and update of markets.

## Bug Fixes

- (x/broker) [#1001](https://github.com/Switcheo/carbon/pull/1001) Fix fee deduction for spot markets to account for net available balances if a trade has been executed.

## V2.47.0 - 2024-08-27

## Features

- (x/broker) [#580](https://github.com/Switcheo/carbon/pull/580) Deduction of fees from priority list of location for creation of closing orders without the need for the user to have available balance.
- (x/cdp) [#793](https://github.com/Switcheo/carbon/pull/793) Refactor of CDP repayment logic and messages into one common transaction flow.
- (x/market) [#933](https://github.com/Switcheo/carbon/pull/933) Addition of methods and validation to activate and deactivate markets, with store separation for faster iteration.

## Improvements

- (api/ws) [#968](https://github.com/Switcheo/carbon/pull/968) Refactor GRPCs for websocket with helper function for retrieving all records without being limited by pagination unintentionally.
- (x/oracle) [#972](https://github.com/Switcheo/carbon/pull/972) Improve oracle handling of decimal precision when dealing with float point data.

## Bug Fixes

- (x/market) [#970](https://github.com/Switcheo/carbon/pull/970) Backfill of missing open interest data for spot markets and markets already settled.
- (x/oracle) [#971](https://github.com/Switcheo/carbon/pull/971) Redeployment of oracle contracts to fix errors in updating price data to contracts.
- (baseapp) [#978](https://github.com/Switcheo/carbon/pull/978) Set configurations required to re-enable ledger support.
- (x/pricing) [#982](https://github.com/Switcheo/carbon/pull/982) Fixed issue where valid pricing results where being delayed by one block.
- (x/cdp) [#990](https://github.com/Switcheo/carbon/pull/990) Added guard to prevent zero division when unlocking collateral with zero LTV.

## Persistence

- (services/archiver) [#852](https://github.com/Switcheo/carbon/pull/852) Archiver service to archive non-essential data and speed up querying of historical information from persistence. Run vacuum full on `transactions`, `messages` to reclaim space after archiving has caught up.

## V2.46.0 - 2024-07-24

## Features

- (x/ccm, x/headersync) [#918](https://github.com/Switcheo/carbon/pull/918) Removal of Zion related code.
- (x/insurance) [#938](https://github.com/Switcheo/carbon/pull/938) Insurance fund eligibility to only liquidity pools with sufficient liquidity to prevent funds from being drained.
- (x/cdp) [#962](https://github.com/Switcheo/carbon/pull/962) Health factor query for checking of health factor against persistence data.
- (services/oracle) [#964](https://github.com/Switcheo/carbon/pull/964) Oracle servicer optimization for faster processing and subaccount oracle delegate support.

## Bug Fixes

- (x/order)[#967](https://github.com/Switcheo/carbon/pull/967) Fix bug where order allocated margin was not properly unmarshalled into Coin type.

## V2.45.0 - 2024-07-08

## Dependencies

- (baseapp) [#b5d1c51](https://github.com/Switcheo/carbon/commit/b5d1c517ac809410e4e19293c2f705ca268507b7) Removal of RocksDB as dependency for all networks.

## Features

- (x/market) [#837](https://github.com/Switcheo/carbon/pull/837) Add an open interest cap on futures markets.
- (baseapp) [#925](https://github.com/Switcheo/carbon/pull/925) Blacklist feature to prevent malicious actors from sending coins out of their address.

## Improvements

- (x/oracle) [#865](https://github.com/Switcheo/carbon/pull/865) Refactor of oracle module EVM methods into evmcontracts module.
- (baseapp) [#888](https://github.com/Switcheo/carbon/pull/888) Refactor naming and usage of cached context for code safety.
- (x/evmcontract) [#945](https://github.com/Switcheo/carbon/pull/945) Refactor evm genesis to start at block height 1 and tests to start at block height 2.
- (baseapp) [#958](https://github.com/Switcheo/carbon/pull/958) Remove legacy proposal code.

## Bug Fixes

- (baseapp) [#928](https://github.com/Switcheo/carbon/pull/928) Fix pagination flag usage on CLI.
- (x/broker) [#954](https://github.com/Switcheo/carbon/pull/954) Fix quoting amount for perpetual AMM to account for position margin and not position PnL.
- (baseapp) [#956](https://github.com/Switcheo/carbon/pull/956) Fix the parsing of admin address for admin message fee.
- (x/oracle) [#957](https://github.com/Switcheo/carbon/pull/957) Fix oracle data parsing and validation bugs.

## Persistence

- (persistence) [#893](https://github.com/Switcheo/carbon/pull/893) Batching the insert and updates of orders to improve persistence processing speed.

## V2.44.0 - 2024-06-26

## Features

- (x/oracle) [#868](https://github.com/Switcheo/carbon/pull/868) Update oracle processing to use tendermint p2p gossip to collate votes.
- (x/pricing) [#870](https://github.com/Switcheo/carbon/pull/870) Add new validation hooks and methods for token price removal.
- (x/liquidation) [#927](https://github.com/Switcheo/carbon/pull/927) Change liquidation order price to reflect the market mark price during liquidation.

## Improvements

- (baseapp) [#913](https://github.com/Switcheo/carbon/pull/913) Combine Cosmos-SDK Swagger and Carbon Swagger documentation into one Swagger UI.
- (baseapp) [#920](https://github.com/Switcheo/carbon/pull/920) Renaming of marketName field and variables to marketId.
- (services/oracle) [#922](https://github.com/Switcheo/carbon/pull/922) Improve error trace for oracle service adapters.
- (perpspool) [#926](https://github.com/Switcheo/carbon/pull/926) Remove the need to specify share token symbol when creating perpetual liquidity pool.
- (baseapp) [#928](https://github.com/Switcheo/carbon/pull/958) Remove legacy proposal code.

## Bug Fixes

- (baseapp) [#911](https://github.com/Switcheo/carbon/pull/911) Fix CLI bug due to misconfiguration of autoCLI signing mode.
- (x/order) [#931](https://github.com/Switcheo/carbon/pull/931) Fix bug where MsgCancelAll was not working as intended.
- (services/oracle) [#932](https://github.com/Switcheo/carbon/pull/923) Fix oracle adapter parsing operations bug.

## Persistence

- (persistence) [#919](https://github.com/Switcheo/carbon/pull/919) Change msg proto type to handle pointer string and migrate empty string to NULL value.
- (persistence) [#935](https://github.com/Switcheo/carbon/pull/935) Clear persistence buffers in BeginBlock and AfterCommit to prevent collection of stale events.

## V2.43.0 - 2024-05-20

## Bug Fixes

- (x/cdp) [#917](https://github.com/Switcheo/carbon/pull/917) Revert state changes from CDP module migration bug.

## V2.42.0 - 2024-05-20

## Features

- (x/liquiditypool) [#864](https://github.com/Switcheo/carbon/pull/864) Remove pools with uneven weights from pool routes and add validation for creating pool routes.

## Improvements

- (baseapp) [#903](https://github.com/Switcheo/carbon/pull/903) Remove unused memStoreKey.
- (baseapp) [#904](https://github.com/Switcheo/carbon/pull/904) Remove usage of WrapSDKContext from tests.
- (baseapp) [#905](https://github.com/Switcheo/carbon/pull/905) Remove deprecated msg.GetSigners method from all messages.
- (x/oracle) [#908](https://github.com/Switcheo/carbon/pull/908) Refactor the removal of oracle to be more explicit in EndBlock.

### Bug Fixes

- (x/profile) [#906](https://github.com/Switcheo/carbon/pull/906) Remove username field in QueryAllProfileRequest gRPC message.
- (x/auth) [#907](https://github.com/Switcheo/carbon/pull/907) Fix bug where the signer in the acc_seq event was not being decoded properly.

## Persistence

- [#884](https://github.com/Switcheo/carbon/pull/884) Extract messages within MsgExec types, update granter and grantee details and flatten messages for storage.

## V2.41.0 - 2024-05-07

### Improvements

- (proto) [#885](https://github.com/Switcheo/carbon/pull/885) Addition of cosmos proto.Scalar options to proto fields for readability.
- (baseapp) [#890](https://github.com/Switcheo/carbon/pull/890) Remove deprecated codec.ProtoMarshaler to proto.Message for keeper marshal and unmarshal.
- (baseapp) [#898](https://github.com/Switcheo/carbon/pull/898) Add grpc-url flag for CLI of all services.

### Bug Fixes

- (api/ws) [#892](https://github.com/Switcheo/carbon/pull/892) Fix websocket updates for DayVolume and QuoteVolume on marketstats subscription.
- (baseapp/evm) [#899](https://github.com/Switcheo/carbon/pull/899) Fix getSigners Metamask eip712 transaction with amino signing.
- (baseapp/evm) [#902](https://github.com/Switcheo/carbon/pull/902) Fix begin/end blocker not running for evm module.

## V2.40.1 - 2024-04-29

### Improvements

- (baseapp) [e38661e](https://github.com/Switcheo/carbon/commit/e38661ebda54aa31429d4287e6307bd00b45491b) Add snapshot CLI commands into root command.

## V2.40.0 - 2024-04-25

### Bug Fixes

- (x/broker) [181fb8f](https://github.com/Switcheo/carbon/commit/181fb8faf83b3994482ecd26fdf8254623ea6d7f) Fix wrong use of context and cachedContext in broker module.

## V2.39.1 - 2024-04-24

### Bug Fixes

- Fix gov proposals query due to missing legacy codec

## V2.39.0 - 2024-03-27

### Dependencies

- [#796](https://github.com/Switcheo/carbon/pull/796) Bump Cosmos-SDK v0.50.5

### Improvements

- [#867](https://github.com/Switcheo/carbon/pull/867) Allow for non-JSON responses for http requests.

### Bug Fixes

- (x/liquiditypool) [#860](https://github.com/Switcheo/carbon/pull/860) Handle expiring markets during quoting of virtual orders.

## V2.38.4 - 2024-03-06

### Bug Fixes

- (x/order) [f606d05] Fix MustKillMarketOrders panic when there are nil market orders to kill.

## V2.38.3 - 2024-03-04

### Bug Fixes

- (x/liquiditypool) [#856](https://github.com/Switcheo/carbon/pull/856) Fix imprecise calculation in GetRewardShare.
- (services/liquidator) [ad9f026] Fix liquidator service not obtaining the full set of prices for liquidation.
- (x/liquiditypool) [#856](https://github.com/Switcheo/carbon/pull/856) Fix imprecise calculation in GetRewardShare.

## V2.38.2 - 2024-02-23

### Bug Fixes

- (baseapp) [327df3c] Fix slow test cases in production tests.

## V2.38.1 - 2024-02-23

### Bug Fixes

- (x/liquiditypool) [#855](https://github.com/Switcheo/carbon/pull/855) Handles negative coins in pool rewards calculation, causing a chain halt at block 54001067.
- (api/ws) [#854](https://github.com/Switcheo/carbon/pull/854) Fix MarketLiquidityUsageMultiplier not updating for new markets.

## V2.38.4 - 2024-03-06

### Bug Fixes

- (x/order) [f606d05] Fix MustKillMarketOrders panic when there are nil market orders to kill.

## V2.38.3 - 2024-03-04

### Bug Fixes

- (services/liquidator) [ad9f026] Fix liquidator service not obtaining the full set of prices for liquidation.

## V2.38.2 - 2024-02-23

### Bug Fixes

- (baseapp) [327df3c] Fix slow test cases in production tests.

## V2.38.1 - 2024-02-23

### Bug Fixes

- (x/liquiditypool) [#855](https://github.com/Switcheo/carbon/pull/855) Handles negative coins in pool rewards calculation, causing a chain halt at block 54001067.
- (api/ws) [#854](https://github.com/Switcheo/carbon/pull/854) Fix MarketLiquidityUsageMultiplier not updating for new markets.

## V2.38.0 - 2024-02-16

### Improvements

- (baseapp) [#807](https://github.com/Switcheo/carbon/pull/807) Fix all unsafe uint to int conversions.
- (baseapp) [#833](https://github.com/Switcheo/carbon/pull/833) Refactor all use of market name to market id for code base.
- (x/broker) [#834](https://github.com/Switcheo/carbon/pull/834) Reduce broker endblock time by optimising ProcessDerisk.
- (baseapp) [#840](https://github.com/Switcheo/carbon/pull/840) Make fields in UpdateParams optional.

### Bug Fixes

- (api/ws) [#817](https://github.com/Switcheo/carbon/pull/817) Add additional events to track edge case for open interest calculation.
- (x/coin) [#830](https://github.com/Switcheo/carbon/pull/830) Enforce checks where 0 withdraw amount is forbidden.
- (x/admin) [#831](https://github.com/Switcheo/carbon/pull/831) Add global flags to populate group proposal message when submitting a multi-sig message.
- (x/broker) [#835](https://github.com/Switcheo/carbon/pull/835) Fix virtual orders being squashed against liquidation orders.
- (x/pricing) [#838](https://github.com/Switcheo/carbon/pull/838) Fix impact price not taking into account virtual orders.
- (x/broker) [#842](https://github.com/Switcheo/carbon/pull/842) Fix ProcessEdits from affect AMM squashing of orders and add InsertedBlockHeight field to ensure edit order is de-prioritized in matching.
- (x/coin) [#843](https://github.com/Switcheo/carbon/pull/843) Add function that updates cibt token decimals to follow base token decimals.
- (x/oracle) [#851] (https://github.com/Switcheo/carbon/pull/851) Add additional checks when creating/updating oracles.

## V2.37.1 - 2024-01-24

### Improvements

- (x/broker) [9df84d28](https://github.com/Switcheo/carbon/commit/9df84d28d10d89cdc432874b2aaace325c681e4c) Reduce broker endblock time by caching GetAllPoolRoute.

## V2.37.0 - 2024-01-19

### Dependencies

- [#732](https://github.com/Switcheo/carbon/pull/732) Bump Cosmos-SDK to v0.47.5.

### Features

- (x/evmcontracts) [#567](https://github.com/Switcheo/carbon/pull/567) Intergration of EVM into `Order`, `Market` and `Position` modules to enable trading via EVM.
- (x/subaccount) [#764](https://github.com/Switcheo/carbon/pull/764) Add grpc query for subaccount cooldown time.
- (x/broker) [#774](https://github.com/Switcheo/carbon/pull/774), [#829](https://github.com/Switcheo/carbon/pull/829) Virtualization of order books to improve block performance.
- (x/auth) [#813](https://github.com/Switcheo/carbon/pull/813) Enable feegrant checks in antehandler decorator for signless transactions.
- (x/baseapp) [#816](https://github.com/Switcheo/carbon/pull/816) Whitelisting of messages authorised for governance proposals.
- (x/baseapp) [#823](https://github.com/Switcheo/carbon/pull/823) Normalization of the module governance proposal handlers to the updated Cosmos-SDK v0.47.5 flow.

### Improvements

- (x/perpspool) [#769](https://github.com/Switcheo/carbon/pull/769) Add quote shape validation for updates to market quote shapes.
- (baseapp) [#778](https://github.com/Switcheo/carbon/pull/778) Upgraded `cosmos/ledger-cosmos-go` to [v0.12.4](https://github.com/cosmos/ledger-cosmos-go/releases/tag/v0.12.4), preventing later versions of ledger firmware results in error with empty message.
- (baseapp) [#785](https://github.com/Switcheo/carbon/pull/785) Validators can run Oracle services and Carbon on separate nodes. by specifying the `--grpc-url` flag.
- [#794](https://github.com/Switcheo/carbon/pull/794) Standardize code base to utilize naming convention "Id" instead of "ID".
- (x/position)[#797](https://github.com/Switcheo/carbon/pull/797) Refactor update position code into simpler sections for trade, funding and set usage. Refactor transfer of coins from order margin to position margin.
- (baseapp) [#798](https://github.com/Switcheo/carbon/pull/798) Add telemetry logs for broker module and subprocesses to monitor performance.
- (x/broker) [#805](https://github.com/Switcheo/carbon/pull/805) Optimize order execution state machine to reduce memory usage.

### Bug Fixes

- (api/ws) [#770](https://github.com/Switcheo/carbon/pull/770) Fixed erroneous updates resulting in negative open interest rate.
- (x/broker) [#771](https://github.com/Switcheo/carbon/pull/771) Orders from Perperutals AMM will always be considered maker orders.
- (x/coin, x/broker, x/liquidation) [#773](https://github.com/Switcheo/carbon/pull/773) Re-initialisation of module addresses without modules accounts. Normalize module address getters to ensure initialization.
- (x/adl) [#782](https://github.com/Switcheo/carbon/pull/782) Fixed deleverage engine from using the wrong PnL value for long position clawsback.
- (docker) [#790](https://github.com/Switcheo/carbon/pull/790) Fixed peer setup for docker nodes.
- (x/broker) [#792](https://github.com/Switcheo/carbon/pull/792) Fixed stale orderbook state during edit orders, resulting in panic when settling markets.
- (api/ws) [#815](https://github.com/Switcheo/carbon/pull/815) Fixed order of websocket updates for recent trades.
- (api/ws) [#821](https://github.com/Switcheo/carbon/pull/821) Fixed file path changes from Cosmos-SDK v0.47.5 for codec generation.
- (x/liquiditypool) [#827](https://github.com/Switcheo/carbon/pull/827) Fixed liquidity pool routes from double usage the same pool for different routes.

### Persistence

- [#636](https://github.com/Switcheo/carbon/pull/636) Addition of foreign keys for all tables.
- [#781](https://github.com/Switcheo/carbon/pull/781) Drop `external_transfers` table.

---

## V2.36.9 - 2024-01-12

### Bug Fixes

- (api/ws) Fixed calculation when adding new token into balances map for balances websocket service.

## V2.36.8 - 2024-01-12

### Bug Fixes

- (api/ws) [#826](https://github.com/Switcheo/carbon/pull/826) Fixed wrong usage of mutex embedded within structs of websocket services.

## V2.36.7 - 2024-01-11

### Bug Fixes

- (api/ws) [#821](https://github.com/Switcheo/carbon/pull/821) Fixed race conditions in destroying websocket subscriptions and global channel keys.
- (api/ws) [#824](https://github.com/Switcheo/carbon/pull/824) Fixed concurrent map read write for base subscription.

## V2.36.6 - 2024-01-11

### Bug Fixes

- (api/ws) [#820](https://github.com/Switcheo/carbon/pull/820) Fixed orphanded goroutines in subscriptions.

## V2.36.5 - 2024-01-09

### Bug Fixes

- (api/ws) [#819](https://github.com/Switcheo/carbon/pull/819) Fixed channel key of candlesticks affecting market chart updates.

## V2.36.4 - 2023-12-21

### Persistence

- [#810](https://github.com/Switcheo/carbon/pull/810) Optimize index scans for position query to database.

## V2.36.3 - 2023-11-11

### Bug Fixes

- (api/ws) [#766](https://github.com/Switcheo/carbon/pull/766) Fix data race conditions for websocket updates.
- (baseapp)[#802](https://github.com/Switcheo/carbon/pull/802) Initialize snapshot directory for RocksDB.

## V2.36.2 - 2023-12-07

### Persistence

- (x/baseapp) Add debug logs for persistence monitoring.

## V2.36.1 - 2023-12-04

### Persistence

- [#636](https://github.com/Switcheo/carbon/pull/636) Addition of foreign keys for all tables.

## V2.36.0 - 2023-11-11

### Features

- (x/market) [#759](https://github.com/Switcheo/carbon/pull/759) Reduced funding rate minimum interval to one minute.

### Improvements

- (x/order) [#742](https://github.com/Switcheo/carbon/pull/742) Refactor and normalize all kill order logic from all books and incoming orders.
- (x/liquiditypool) [#761](https://github.com/Switcheo/carbon/pull/761) Add event for changes to liquidity pool's reward curves.

### Bug Fixes

- (x/liquiditypool) [#763](https://github.com/Switcheo/carbon/pull/763) Fix allocated claim counter having insufficient coins to claim liquiditypool rewards causing chain panic.
- (x/coin) [#767](https://github.com/Switcheo/carbon/pull/767) Fix coin validation when creating new coins.

### State Machine Breaking

- (x/params) [#760](https://github.com/Switcheo/carbon/pull/760) Migration of module parameters from x/params module (deprecated in SDK v0.47.5) to owner module's store.

### Persistence

- [#720](https://github.com/Switcheo/carbon/pull/720) Backfill of missing entry in `orders` table.
