# This project is under the creation
## Usage
DeFi__GoldenGateBridge is a bridge project loosely based on the Optimism project which allows us
to bridge our custome ERC20 token from leyer1 to layer2 and vise versa.
Also bridging the ETH from layer1 to layer2 (also vise versa) is also permitted.
GoldenGateBridge is used as the entry point for interacting with Optimism network and sending
message architecture from layerX to layerY is basically based on the ICrossDomainMessenger from the  
Optimism network.

## GoldenGateBridge Architecture
![GoldenBridgeArchitecture](/GoldenBridgeArchitecture.png 'Golden Gate Bridge Architecture')

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

```shell (Afther your .env file is ready)
$ forge script script/GoldenBridgeArchitecture.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
