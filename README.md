# Prototype (PoC) for Taking Advantage of the DexTwo Vulnerability
## Introduction
Because there are no safeguards against the tokens being switched, the DexTwo smart contract is susceptible to manipulation. 

Due to this vulnerability, the genuine tokens (tokens 1 and 2) in the DexTwo contract can have their liquidity drained by an attacker using a custom token.

## An explanation of vulnerability
Swap, the primary feature of the DexTwo contract, enables users to switch tokens 1 and 2 for one another. The quantity of tokens obtained in a swap is calculated by the contract using the following formula:

```
uint256 swapAmount = (amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this));

```
Because this calculation depends on the balance of tokens in the DexTwo contract and there is no validation on the tokens being swapped, it might be abused. 

By creating a bespoke token and manipulating the swap rates, an attacker can finally deplete the DexTwo contract of its valid tokens.

### Exploit
The test_drain_dex_with_fake_token function performs a series of swaps using the FakeToken to drain the legitimate tokens from the DexTwo contract.
The initial swaps are followed by additional smaller swaps to ensure all tokens are drained.

### Assertions:
After the exploit, the balances of token1 and token2 in the DexTwo contract are checked to ensure they are zero, confirming the contract has been drained.

```
// Assert the DexTwo contract is drained
        assertEq(token2.balanceOf(address(dex)), 0);
        assertEq(token1.balanceOf(address(dex)), 0)
```

# Proof of Concept (PoC) Report: Taking Advantage of Precision Loss inDex Contract
This Proof of Concept illustrates how to take advantage of a flaw in the Dex contract, namely the loss of precision in the getSwapPrice function as a result of Solidity's integer division. 

An attacker can deplete one of the tokens from the Dex contract's liquidity by carefully carrying out a sequence of token swaps.

## Description of Vulnerability
The swap function in the Dex contract enables token changing between two different tokens. The `getSwapPrice` function employs integer division to determine how many tokens will be received in a swap; this results in an accuracy loss (rounding down to the nearest integer). 

This accuracy loss can be used to repeatedly trade tokens, thus depleting the liquidity of a single token.

The swap function allows swapping a specified amount of token1 for token2, or vice versa.
The getSwapPrice function calculates the swap price using the formula:
```
swapAmount =
(amount × balance of token2) / balance of token1
swapAmount=(amount×balance of token2)/balance of token1
```

This results in rounding down to the nearest integer due to the lack of floating-point precision.

After the swaps, the attacker should have more tokens than they started with.
One of the token balances in the Dex contract should be zero, indicating that the liquidity has been drained from either token1 or token2.