# TFM

# Auditoría de Seguridad sobre contrato 01-unstoppable

## Análisis Estático 

### Silther

```shell
$ slither src/contracts/01-unstoppable
```

### Mythril

#### Análisis Local

```shell
$ myth analyze src/contracts/01-unstoppable/UnstoppableVault.sol  src/contracts/01-unstoppable/ReceiverUnstoppable.sol --solc-json mythril.json --solv 0.8.23
```

#### Análisis on-chain

Para llevar a cabo este análisis es necesario desplegar los contratos en una red. Para ello utilizaremos Anvil que nos permitirá crear una testnet local de Ethereum, similar a Ganache, en nuestra máquina. Los pasos serían los siguientes:

1. Ejecutar Anvil
```shell
$ anvil
```
Esta ejecución lo que hará será levantar un nodo con un listado de cuentas y private keys asociadas para probar.

2. Desplegamos los contratos siguiendo el siguiente comando de forge :

```shell
$ forge create --rpc-url <your_rpc_url> --private-key <your_private_key> src/MyContract.sol:MyContract
```

2.1 Despligue de DamnValuableToken:

```shell
$ forge create --rpc-url http://127.0.0.1:8545 --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/contracts/DamnValuableToken.sol:DamnValuableToken
```

Donde 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 es una de las private keys proporcionada por Anvil.

Como salida obtenemos quien ha realizado el despliegue (Deployer), cual es la dirección del contrato desplegado (Deployed to) seguido del hash de la transacción.

2.2 Despligue de UnstoppableVault:

El contructor de este contrato requiere tres argumentos de entrada:

constructor(ERC20 _token, address _owner, address _feeRecipient)

La dirección del token , la direccion del dueño del contrato (_owner) y , por último, la dirección de quien va a recibir las comisiones de los préstamos flash (_feeRecipient). Por lo tanto, utilizamos como dirección del token, la dirección del contrato DamnValuableToken que acabamos de desplegar y para las otras dos direcciones vamos a utilizar la misma dirección de quien despliega el contrato

```shell
$ forge create --rpc-url http://127.0.0.1:8545 --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/contracts/01-unstoppable/UnstoppableVault.sol:UnstoppableVault
```
2.3 Despligue de ReceiverUnstoppable:

En este caso el constructor de este contrato requiere un parámetro de entrada y corresponde con la dirección del vault, por lo tanto, le pasaremos al contructor la direccion del contrato vault UnstoppableVaul que acabamos de desplegar.

```shell
$ forge create --rpc-url http://127.0.0.1:8545 --constructor-args 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/contracts/01-unstoppable/ReceiverUnstoppable.sol:ReceiverUnstoppable 
```

Una vez realizado el despliegue ejecutamos Mythril:

```shell
$ myth analyze -a <dirección smart contract> --rpc 127.0.0.1:8545
```

Donde -a <dirección smart contract> especifica la dirección del contrato desplegado a analizar y --rpc 127.0.0.1:8545 especifica la red donde estan desplegados los contratos.