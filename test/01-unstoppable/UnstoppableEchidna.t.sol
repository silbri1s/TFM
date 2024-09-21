// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Util.sol";
import {DamnValuableToken} from "../../src/contracts/DamnValuableToken.sol";
import {UnstoppableVault} from "../../src/contracts/01-unstoppable/UnstoppableVault.sol";
import {ReceiverUnstoppable} from "../../src/contracts/01-unstoppable/ReceiverUnstoppable.sol";
import {ERC20} from "solmate/src/tokens/ERC4626.sol";
import "solmate/src/utils/FixedPointMathLib.sol";
import "forge-std/console.sol";


contract UnstoppableEchidnaTest{
    using FixedPointMathLib for uint256;

    uint256 internal constant TOKENS_IN_VAULT = 1_000_000e18;
    uint256 internal constant INITIAL_PLAYER_TOKEN_BALANCE = 100e18;
    uint256 internal constant FEE_FACTOR = 0.05 ether;

    Util internal util;

    UnstoppableVault internal vault;
    ReceiverUnstoppable internal receiverContract;
    DamnValuableToken internal token;

    address payable internal deployer;
    address payable internal player;

    constructor() {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        util = new Util();
        address payable[] memory users = util.createUsers(2);
        deployer = users[0];
        player = users[1];

        token = new DamnValuableToken();
        vault = new UnstoppableVault(ERC20(token), deployer, deployer); // owner and fee recipient
        receiverContract = new ReceiverUnstoppable(address(vault));

        //Send tokens to vault
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(deployer));

        //Send tokens to player
        token.transfer(address(player), INITIAL_PLAYER_TOKEN_BALANCE);
    }

    // Verifica si se puede ejecutar préstamo flash
    function echidna_receiver_can_execute_flah_loan() public returns (bool) {
        // Ejecutar el préstamo flash
        receiverContract.executeFlashLoan(10);
        return true;
    }


    // Comprueba si la cantidad de tokens en el vault es igual a la cantidad 
    // total de tokens representados por las acciones del vault
    function echidna_vault_balance_equal_token_balance() public view returns (bool) {
       // Obtén el balance del contrato antes de ejecutar la transacción flashLoan
        uint256 balanceBefore = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();

         // Verifica si el balance antes de la transacción es igual al total de acciones
        return vault.convertToShares(totalSupply) == balanceBefore;
    }


    // Verifica si el préstamo se devuelve correctamente
    function echidna_flash_loan_is_repaid() public returns (bool) {
        uint256 amount = 5e18;

        // Asegúrate de que el contrato del jugador tenga suficientes tokens para pagar el préstamo
        //token.transfer(address(receiverContract), amount + amount.mulWadUp(FEE_FACTOR));

        uint256 vaultBalancePre = token.balanceOf(address(vault));
        // Ejecutar el préstamo flash
        receiverContract.executeFlashLoan(amount);

        // Verificar el saldo del vault después del préstamo
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
       
        // Calcular la cantidad esperada del préstamo + tarifa
        uint256 fee = vault.flashFee(address(token), amount);
        uint256 expectedAmount = vaultBalancePre + fee;

        // Verificar si el saldo del vault coincide con el monto esperado
        return vaultBalanceAfter == expectedAmount;
    }


    // test para garantizar que se cobren las tarifas adecuadas por los préstamos flash
    function echidna_flash_loan_repays_properly() public view returns (bool) {
        uint256 amount = 5e18;
        //Calcula las tasas asociadas 
        uint256 fee = vault.flashFee(address(token), amount);
        return fee <= amount.mulWadUp(FEE_FACTOR);
    }

    // Test para garantizar que el retiro se comporte correctamente
    function echidna_withdraw_behaves_correctly() public returns (bool) {
        uint256 depositAmount = 1e18; // Cantidad de deposito inicial

        // Depositar tokens en el vault
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, address(player));

        // Calcular la cantidad de acciones del jugador
        uint256 playerShares = vault.balanceOf(address(player));

        // Retirar la misma cantidad de tokens
        vault.withdraw(playerShares, address(player), address(player));

        // Verificar el saldo del jugador después del retiro
        uint256 playerBalanceAfter = token.balanceOf(address(player));

        // Verificar si el saldo del jugador coincide con el monto retirado
        return playerBalanceAfter >= depositAmount;
    }
}