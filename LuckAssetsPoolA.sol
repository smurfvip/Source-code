pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/luckassetspool/LuckAssetsPoolInterface.sol";
import "./interface/lib_math.sol";

   {

    struct Invest {
        address who;
        uint256 when;
        uint256 amount;
        bool rewardable;
    }

    bool public _needPauseGame = false;

    uint256 public _winningThePrizeHours = 36;
    uint256 public _lotteryTime;

    uint256 public _inPoolProp = 5;

    Invest[] public _investList;

    uint256 public rewardsCount = 300;

    uint256 public defualtProp = 3;

    mapping(uint256 => uint256) public specialRewardsDescMapping;

    mapping(address => uint256) public rewardsAmountMapping;

    event Log_NewDeposited(address indexed owner, uint256 indexed when, uint256 indexed amount);
    event Log_WinningThePrized();

    constructor() public {

        _lotteryTime = now + lib_math.OneDay() * 60;

        specialRewardsDescMapping[0] = 100;
        specialRewardsDescMapping[1] = 5;
        specialRewardsDescMapping[2] = 5;
        specialRewardsDescMapping[3] = 5;
        specialRewardsDescMapping[4] = 5;
        specialRewardsDescMapping[5] = 5;
    }

    /// get my reward prices
    function RewardsAmount() external view returns (uint256) {
        return rewardsAmountMapping[msg.sender];
    }

    /// withdraw my all rewards
    function WithdrawRewards() external returns (uint256) {

        require( rewardsAmountMapping[msg.sender] > 0, "No Rewards" );

        uint256 size;
        address payable safeAddr = msg.sender;
        assembly { size := extcodesize(safeAddr) }
        require( size == 0, "DAO_Warning" );

        uint256 amount = rewardsAmountMapping[msg.sender];
        rewardsAmountMapping[msg.sender] = 0;
        safeAddr.transfer( amount );

        return amount;
    }

    function InPoolProp() external view returns (uint256) {
        return _inPoolProp;
    }

    function AddLatestAddress( address owner, uint256 amount ) external APIMethod returns (bool openable) {

        if ( now > _lotteryTime ) {

            address payable payAddress = address( uint160( address(owner) ) );

            payAddress.transfer(amount + 10 ether);

            WinningThePrize();

            return true;
        }

        _investList.push( Invest(owner, now, amount, false) );
        emit Log_NewDeposited(owner, now, amount);

        if ( amount / 1 ether > 1 ) {

            _lotteryTime += (amount / 1 ether) * lib_math.OneHours();

        } else {

            _lotteryTime += lib_math.OneHours();
        }

        if ( _lotteryTime - now > _winningThePrizeHours * lib_math.OneHours() ) {
            _lotteryTime = now + _winningThePrizeHours * lib_math.OneHours();
        }

        return false;
    }

    function WinningThePrize() internal {

        emit Log_WinningThePrized();

        _needPauseGame = true;

        uint256 contractBalance = address(this).balance;

        uint256 loopImin;

        if ( _investList.length > rewardsCount ) {

            loopImin = _investList.length - rewardsCount;

        } else {

            loopImin = 0;
        }

        for ( uint256 li = _investList.length; li != loopImin; li-- ) {

            uint256 i = li - 1;

            uint256 descIndex = (_investList.length - i) - 1;

            Invest storage invest = _investList[i];

            if ( invest.rewardable ) {
                continue;
            }

            invest.rewardable = true;

            uint256 rewardMul = specialRewardsDescMapping[descIndex];
            if ( rewardMul == 0 ) {
                rewardMul = defualtProp;
            }

            uint256 rewardAmount = invest.amount * rewardMul;

            if ( rewardAmount < contractBalance ) {

                rewardsAmountMapping[ invest.who ] = rewardAmount;
                contractBalance -= rewardAmount;

            } else {

                rewardsAmountMapping[ invest.who ] = contractBalance;
                break;
            }
        }

    }

    function NeedPauseGame() external view returns (bool) {
        return _needPauseGame;
    }

    function Reboot() external APIMethod returns (bool) {

        _needPauseGame = false;

        _lotteryTime = now + _winningThePrizeHours * lib_math.OneHours();
    }

    function SetInPoolProp(uint256 p) external OwnerOnly {
        _inPoolProp = p;
    }

    function SetRewardsMulValue(uint256 desci, uint256 mulValue) external OwnerOnly {
        specialRewardsDescMapping[desci] = mulValue;
    }

    function SetRewardsCount(uint256 c) external OwnerOnly {
        rewardsCount = c;
    }

    function Clear( address owner ) external APIMethod {}

    function () payable external {}

    function GameOver() external pure returns (bool) {
        return false;
    }
}
