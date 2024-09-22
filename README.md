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

Donde -a <dirección smart contract> especifica la dirección del contrato desplegado a analizar y --rpc 127.0.0.1:8545 especifica la red donde estan desplegados los contratos. En nuestro caso, utilizaremos la direccion  0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 que se corresponde con la dirección del contrato desplegado UnstoppableVault

```shell
$ myth analyze -a 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --rpc 127.0.0.1:8545
```

## Análisis Dinámico

### Echidna

A continuación realizamos el análisis dinámico utilizando la herramienta Echidna. Para ellos vamos a crear varios casos de prueba específicos para cubrir diferentes escenarios de uso del contrato. Dichos casos de prueba se encuentran en /test/01-unstoppable/UnstoppableEchidna.t.sol

Una vez tenemos los escenarios para el testeo creamos el archivo de configuración de echidna UnstoppableEchidna.yaml, necesario para la ejecución, con lo siguientes parámetros:
```shell
$
allContracts: true

cryticArgs: ["--foundry-compile-all"]
```

Donde el primer parámetro <allContracts> permite que se utilice las funciones public y external de todos los contratos necesarios que utiliza y  el segundo <cryticArgs: "--foundry-compile-all"]> para indicar que utilice fondry para la compilación de los test. Indicar que no es necesario a\ñadir el modo de test a utilizar ya que por defecto es el modo "property" y se corresponde con los test que hemos implementado, donde estamos especificando propiedades o funciones públicas en el contrato que devolver un valor booleano indicando si la propiedad se cumple o no.

```shell
$ echidna --config test/01-unstoppable/UnstoppableEchidna.yaml test/01-unstoppable/UnstoppableEchidna.t.sol --contract UnstoppableEchidnaTest
```

## Análisis Manual

Conseguimos superar el challenge propuesto y que el Vault deje de ofrecer préstamos flash si hacemos un transfer al vault. Para ello he creado un test en "forge" donde se realiza dicho exploit, este se encuentra en test/01-unstoppable/Unstoppable.t.sol

Para ejecutarlo el comando es el siguiente: 

```shell
$ forge test --match-path test/01-unstoppable/Unstoppable.t.sol
```