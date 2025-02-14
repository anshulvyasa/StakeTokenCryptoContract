// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingDapp is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    constructor() Ownable(msg.sender) {}

    //defining Structure for User
    struct UserInfo {
        uint256 amount;
        uint lastRewardAt;
        uint256 lockUntil;
    }

    //Defining Structure for PoolInfo
    struct PoolInfo {
        IERC20 depositToken;
        IERC20 rewardToken;
        uint256 depositedAmount;
        uint256 apy;
        uint lockDays;
    }

    //defining Structure for Notification
    struct Notification {
        uint256 poolID;
        uint256 amount;
        address user;
        string typeOf;
        uint256 timestamp;
    }

    //defining some important variable
    uint constant decimal = 10 ** 18;
    uint public poolCount;

    //defining pollArray and notification array
    PoolInfo[] public poolInfo;
    Notification[] public notifications;

    //defining some necessary mapping here.
    mapping(address => uint256) public depositedTokens;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    //Adding pool for staking purpose
    function addPoll(
        IERC20 _depositedToken,
        IERC20 _rewardToken,
        uint _apy,
        uint _lockDays
    ) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                depositToken: _depositedToken,
                rewardToken: _rewardToken,
                depositedAmount: 0,
                apy: _apy,
                lockDays: _lockDays
            })
        );

        poolCount++;
    }

    //adding fund to a particular pool
    function deposits(uint _pid, uint _amount) public nonReentrant {
        require(_amount > 0, "Amount should be greater than 0!");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint pending = _calcPendingReward(user, _pid);
            pool.rewardToken.transfer(msg.sender, pending);

            _createNotification(_pid, pending, msg.sender, "Claim");
        }

        pool.depositToken.transferFrom(msg.sender, address(this), _amount);

        pool.depositedAmount += _amount;
        user.amount += _amount;
        user.lastRewardAt = block.timestamp;

        user.lockUntil = block.timestamp + (pool.lockDays * 86400);

        depositedTokens[address(pool.depositToken)] += _amount;
        _createNotification(_pid, _amount, msg.sender, "Deposit");
    }

    function withdraw(uint _pid, uint _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];  

        require(user.amount > _amount, "WithDrawl amount exceeds the balance");
        require(user.lockUntil <= block.timestamp, "Lock is Active");   

        uint256 pending = _calcPendingReward(user, _pid);
        if (user.amount > 0) {
            pool.rewardToken.transfer(msg.sender, pending);
            _createNotification(_pid, pending, msg.sender, "Claim");
        }

        if (_amount > 0) {
            user.amount -= _amount;
            pool.depositedAmount -= _amount;
            depositedTokens[address(pool.depositToken)] -= _amount;
            pool.depositToken.transfer(msg.sender, _amount);
        }

        user.lastRewardAt = block.timestamp;
        _createNotification(_pid, _amount, msg.sender, "WithDraw");
    }

    function _calcPendingReward(
        UserInfo storage user,
        uint _pid
    ) internal view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];

        uint daysPassed = (block.timestamp - user.lastRewardAt) / 86400;

        if (daysPassed > pool.lockDays) {
            daysPassed = pool.lockDays;
        }

        return ((user.amount * daysPassed) / 365) * pool.apy;
    }

    function pendingReward(
        uint _pid,
        address _user
    ) public view returns (uint) {
        UserInfo storage user = userInfo[_pid][_user];
        return _calcPendingReward(user, _pid);
    }

    function sweep(address token, uint256 _amount) external onlyOwner {
        uint256 token_balance = IERC20(token).balanceOf(address(this));

        require(_amount <= token_balance, "Amount exceeds balance");
        require(
            token_balance - _amount >= depositedTokens[token],
            "Can't withDraw deposited token"
        );

        IERC20(token).transfer(msg.sender, _amount);
    }

    function modifyPool(uint _pid, uint _newapy) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.apy = _newapy;
    }

    function claimReward(uint _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.lockUntil <= block.timestamp, "Lock is Active");

        uint256 pending = _calcPendingReward(user, _pid);
        require(pending > 0, "No Reward to claim");

        user.lastRewardAt = block.timestamp;
        pool.rewardToken.transfer(msg.sender, pending);
        _createNotification(_pid, pending, msg.sender, "WithDraw");
    }

    function _createNotification(
        uint _pid,
        uint _amount,
        address _user,
        string memory _typeOf
    ) internal {
        notifications.push(
            Notification({
                poolID: _pid,
                amount: _amount,
                user: _user,
                typeOf: _typeOf,
                timestamp: block.timestamp
            })
        );
    }

    function getNotification() public view returns (Notification[] memory) {
        return notifications;
    }
}
