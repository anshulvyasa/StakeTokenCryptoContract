pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TokenICO} from "src/TokenICO.sol";
import {StakeToken} from "src/StakeToken.sol";

contract TokenICOTest is Test {
    TokenICO ico;
    StakeToken st;
    address user1;

    function setUp() public {
        ico = new TokenICO();
        st = new StakeToken();
        user1 = address(0x123);
    }

    receive() external payable {}

    function testSalePrice() public {
        ico.updateTokenSalePrice(1);
        assertEq(uint(1), ico.tokenSalePrice());
    }

    function testUpdateTokenAddress() public {
        ico.updateTokenAddress(address(st));
        assertEq(address(st), ico.tokenAddress());
    }

    function testICOTokenBalance() public {
        st.mint(address(ico), 10 ** 18);
        assertEq(st.balanceOf(address(ico)), 10 ** 18);
    }

    function testBuyToken() public {
        //minting some token to our ICOToken Contract
        st.mint(address(ico), 10 * 1e18);
        assertEq(st.balanceOf(address(ico)), 10 * 1e18);
        ico.updateTokenSalePrice(1e18);

        //updatingTokenAddress
        ico.updateTokenAddress(address(st));

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        ico.buyToken{value: 1 ether}(1);
    }

    function testGetTokenDetails() public {
        ico.updateTokenAddress(address(st));

        (
            string memory name,
            string memory symbol,
            uint256 balance,
            uint256 supply,
            uint256 tokenPrice,
            address tokenAddres
        ) = ico.getTokenDetails();

        assertEq(name, "StakeToken");
        assertEq(symbol, "STK");
        assertEq(balance, 0);
        assertEq(supply, 0);
        assertEq(tokenPrice, 0);
        assertEq(tokenAddres, address(st));
    }

    function testWithDrawOwner() public {
        ico.updateTokenAddress(address(st));
        st.mint(address(ico), 10 * 1e18);
        assertEq(st.balanceOf(address(ico)), 10 * 1e18);

        ico.withdrawAllToken();
        assertEq(st.balanceOf(address(this)), 10*1e18);
        assertEq(st.balanceOf(address(ico)), 0);
    }
}
