pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";
import {StakeToken} from "src/StakeToken.sol";

contract StakeTokenTest is Test {
    StakeToken st;
    address user1;
    address user2;

    function setUp() public {
        st = new StakeToken(); // Ensure StakeToken's constructor allows this
        user1 = address(uint160(0x124)); // Convert to a proper address
        user2 = address(uint160(0x125));
    }

    function testImageUrl() public {
        st.changeTokenImageURL("ansh");
        string memory url = st.getTokenImageUrl();
        assertEq("ansh", url);
    }

    function testMintToken() public {
        st.mint(user1, 100);
        assertEq(st.balanceOf(user1), 100);
    }

    function testFailMint() public {
        st.mint(user1, 100);
        assertEq(st.balanceOf(user1), 10);
    }

    function testBurn() public {
        st.mint(user1, 100);
        st.burn(user1, 10);
        assertEq(st.balanceOf(user1), 90);
    }

    function testFailBurn() public {
        st.mint(user1, 100);
        st.burn(user1, 10);
        assertEq(st.balanceOf(user1), 10);
    }

    function testTransfer() public {
        st.mint(user1, 100);
        vm.prank(user1); //  ohh boy i forget this step
        st.transfer(user2, 100);

        assertEq(st.balanceOf(user1), 0);
        assertEq(st.balanceOf(user2), 100);
    }

    function testFailTrandfer() public {
        st.mint(user1, 100);
        st.transfer(user2, 100);

        assertEq(st.balanceOf(user1), 0);
        assertEq(st.balanceOf(user2), 100);
    }

    function testApprove() public {
        st.mint(user1, 100);
        vm.prank(user1);
        st.approve(user2, 50);
        uint amount = st.allowance(user1, user2);
        assertEq(amount, 50);
    }

    function testFailApprove() public {
        st.mint(user1, 100);
        st.approve(user2, 50);
        uint amount = st.allowance(user1, user2);
        assertEq(amount, 50);
    }

    function testTransferFrom() public {
        st.mint(user1, 100);
        vm.prank(user1);
        st.approve(user2, 50);

        vm.prank(user2);
        bool status = st.transferFrom(user1, user2, 20);
        assert(status);
    }

    function testName() public {
        string memory name = st.name();
        assertEq(name, "StakeToken");
    }

    function testSymbol() public {
        string memory symbol = st.symbol();
        assertEq(symbol, "STK");
    }

    function testTotalSupply() public {
        uint totalSupply = st.totalSupply();
        assertEq(totalSupply, uint(0));

        st.mint(user1, 100);
        totalSupply = st.totalSupply();

        assertEq(totalSupply, uint(100));
    }
    function testFailTotalSupply() public {
        uint totalSupply = st.totalSupply();
        assertEq(totalSupply, uint(0));

        st.mint(user1, 100);
        totalSupply = st.totalSupply();

        assertEq(totalSupply, uint(50));
    }
}
