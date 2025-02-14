pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {StakingDapp} from "src/StakingDApp.sol";
import {StakeToken} from "src/StakeToken.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingDAppTest is Test {
    StakingDapp sdapp;
    StakeToken st;
    address user1;

    struct Notification {
        uint256 poolID;
        uint256 amount;
        address user;
        string typeOf;
        uint256 timestamp;
    }

    Notification[] public notifications;

    function setUp() public {
        sdapp = new StakingDapp();
        st = new StakeToken();
        user1 = address(0x123);

        // giving some token to our user1
        st.mint(user1, 10 * 1e18);

        //giving some token to our staking contarct
        st.mint(address(sdapp), 100 * 1e18);
    }

    //checking add pool functionality
    function testAddNewPoll() public {
        //adding pool to our etherium global state
        sdapp.addPoll(st, st, 100, 1);

        //getting pool data
        (
            IERC20 depositToken,
            IERC20 rewardToken,
            uint depositedAmount,
            uint apy,
            uint lockDays
        ) = sdapp.poolInfo(0);

        //assertions
        //0. checking if pool Count increased by 1
        assertEq(sdapp.poolCount(), 1);

        //1. checking depositToken
        assertEq(address(depositToken), address(st));

        //2. checking rewardToken
        assertEq(address(rewardToken), address(st));

        //3. checking deposited amount
        assertEq(depositedAmount, 0);

        //4. checking apy
        assertEq(apy, 100);

        //5. checking LockDays
        assertEq(lockDays, 1);
    }

    //checking deposit Fail functionality
    function testFailDeposit() public {
        //adding pool
        sdapp.addPoll(st, st, 100, 1);

        //sending request on behalf on user1
        vm.prank(user1);
        sdapp.deposits(0, 1 * 1e18); //this will fail because we are using transferFrom functionality but we do not allow our target contract to withdraw fund from our account
    }

    //checking deposit functonality
    function testDeposit() public {
        //adding pool
        sdapp.addPoll(st, st, 100, 1);

        //giving our user some token
        st.mint(user1, 10 * 1e18);

        //allowing my StakingToken to spend some fund on my behalf (on user1 behalf)
        vm.prank(user1);
        st.approve(address(sdapp), 1 * 1e18);

        //depositing to StakeContract in behalf of user1
        vm.prank(user1);
        sdapp.deposits(0, 1 * 1e18);

        //what remaining things are left yet to check here
        //1. pool deposit amount is upgrading properly or not.
        //2. the amount user staked is updating properly or not.
        //2. lastReward timeStamp is updating properly or not.
        //2. lockUntil is updating properly.
        //3. the total fund of a partiular token is updating in map properly or not.
        //4. createNotification is working properly or not.

        //pool deposit amount is upgrading properly or not.
        (
            IERC20 depositToken,
            IERC20 rewardToken,
            uint depositedAmount,
            uint apy,
            uint lockDays
        ) = sdapp.poolInfo(0);
        assertEq(depositedAmount, 1 * 1e18);

        // the amount user staked is updating properly or not.
        // lastReward timeStamp is updating properly or not.
        // lockUntil is updating properly.
        (uint256 amount, uint lastRewardAt, uint256 lockUntil) = sdapp.userInfo(
            0,
            user1
        );

        assertEq(amount, 1 * 1e18);
        assertEq(lastRewardAt, block.timestamp);
        assertEq(lockUntil, block.timestamp + 86400);

        // the total fund of a partiular token is updating in map properly or not.
        uint fund = sdapp.depositedTokens(address(st));
        assertEq(fund, 1 * 1e18);

        // createNotification is working properly or not.
        StakingDapp.Notification[] memory notifications = sdapp
            .getNotification();
        uint notificationsLen = notifications.length;

        for (uint i = 0; i < notificationsLen; i++) {
            console.log("Notification %s:", i);
            console.log("Pool ID:", notifications[i].poolID);
            console.log("Amount:", notifications[i].amount);
            console.log("User Address:", notifications[i].user);
            console.log("Type:", notifications[i].typeOf);
            console.log("Timestamp:", notifications[i].timestamp);
            console.log("----------------------------");
        }

        //now there's one last thing to do now
        //suppose you deposit some fund into some pool and now you wanna deposit some more fund to it
        //so the thing is according to our logic you will get reward corresponding to your fund then your new deposited fund will be added to the old one.
        //now we have to check if you are getting reward token or not.

        //approving the StakingContarct to spend fund on my behalf
        vm.prank(user1);
        st.approve(address(sdapp), 5 * 1e18);

        //depositing token fund to the StakingContarct
        vm.startPrank(user1);
        vm.warp(block.timestamp + 43200); //spent half day here
        sdapp.deposits(0, 5 * 1e18);
        vm.stopPrank();

        //checking reward through notifications
        StakingDapp.Notification[] memory notifications1 = sdapp
            .getNotification();

        console.log("Pool ID:", notifications1[1].poolID);
        console.log("Amount:", notifications1[1].amount);
        console.log("User Address:", notifications1[1].user);
        console.log("Type:", notifications1[1].typeOf);
        console.log("Timestamp:", notifications1[1].timestamp);
        console.log("----------------------------");
    }

    //checking withDraw functionality
    function testWithDraw() public {
        //adding pool
        sdapp.addPoll(st, st, 100, 1);

        //approving StakeContract  to spend on behalf of user1
        vm.prank(user1);
        st.approve(address(sdapp), 5 * 1e18);

        //depositing to StakeTokenContract by user1
        vm.prank(user1);
        sdapp.deposits(0, 5 * 1e18);

        //moving 1 day forward in time
        vm.warp(block.timestamp + 86400);

        vm.prank(user1);
        sdapp.withdraw(0, 1);

        StakingDapp.Notification[] memory notifications = sdapp
            .getNotification();

        //so there will be three notification
        //1) for deposit fund
        //2) for claiming reward claiming
        //3) for withdrawing funds
        assertEq(notifications.length, 3);
    }

    //checking testPendingReward functionality
    function testPendingReward() public {
        //adding pool
        sdapp.addPoll(st, st, 100, 1);

        //approving StakeContract  to spend on behalf of user1
        vm.prank(user1);
        st.approve(address(sdapp), 5 * 1e18);

        //depositing to StakeTokenContract by user1
        vm.prank(user1);
        sdapp.deposits(0, 5 * 1e18);

        //moving half day in time
        vm.warp(block.timestamp + 86400);

        uint pendingReward = sdapp.pendingReward(0, user1);

        assertEq(pendingReward, 1369863013698630100);
    }

    //that sweep testing logic
    function sweepTestLogic(IERC20 token, uint _amount) public {
        //adding pool
        sdapp.addPoll(token, token, 100, 1);

        //approving StakeContract  to spend on behalf of user1
        vm.prank(user1);
        st.approve(address(sdapp), 5 * 1e18);

        //depositing to StakeTokenContract by user1
        vm.prank(user1);
        sdapp.deposits(0, 5 * 1e18);

        sdapp.sweep(address(st), _amount * 1e18);
    }

    //checking sweeping  functionality is passing
    function testSweep() public {
        sweepTestLogic(st, 100);
    }
    //checking sweeping functionality is failing
    function testFailSweep() public {
        sweepTestLogic(st, 105);
    }

    //checking modify pool
    function testModifyPoll() public {
        //adding poll
        sdapp.addPoll(st, st, 100, 1);

        //modifying apy of the pool
        sdapp.modifyPool(0, 1000);

        (, , , uint256 apy, ) = sdapp.poolInfo(0);

        assertEq(apy, 1000);
    }

    function testClaimReward() public {
        //adding pool
        sdapp.addPoll(st, st, 100, 1);

        //approving StakeToken contarct to spend some funcd on my behalf and depositing to stakeing token
        vm.startPrank(user1);
        st.approve(address(sdapp), 5 * 1e18);
        sdapp.deposits(0, 5 * 1e18);

        //moving foward in time
        vm.warp(block.timestamp + 86400);

        //claiming the reward
        sdapp.claimReward(0);

        assertEq(6369863013698630100, st.balanceOf(address(user1)));
        vm.stopPrank();
    }
}
