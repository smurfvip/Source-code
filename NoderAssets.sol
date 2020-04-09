pragma solidity >=0.5.0 <0.6.0;

import "./BaseAssetPool.sol";
import "./interface/levelsub/LevelSubInterface.sol";

// function ManagerListOfLevel( uint256 lv ) external view returns (address[] memory addrs);
   {

    uint256 public _latestBonusTime;

    LevelSubInterface public _LVInc;

    event Log_BonusDetail(address indexed owner, uint256 indexed time, uint256 indexed value);
    event Log_Bonus(uint256 indexed time, uint256 totalCount, uint256 totalValue);

    constructor(LevelSubInterface lvinc) public {
        _LVInc = lvinc;
        _latestBonusTime = now;
    }

    function Status() external view returns (
        uint256 balance,
        uint256 c,
        uint256 p,
        uint256 lbt,
        bool canBonus
    ) {
        balance = address(this).balance;

        c = _LVInc.Noders().length;

        p = balance  / c;

        lbt = _latestBonusTime;

        canBonus = (now - lbt) >= lib_math.OneDay() * 7;
    }

    function DoBonus() external OwnerOnly {

        uint256 bonusAmount = _realBalance;

        address[] memory nodeAddresses = _LVInc.Noders();

        uint256 profix = bonusAmount / nodeAddresses.length;

        for ( uint i = 0; i < nodeAddresses.length; i++ ) {

            AddWithdrawValue( nodeAddresses[i], profix );

            emit Log_BonusDetail(nodeAddresses[i], now, profix);
        }

        emit Log_Bonus(now, nodeAddresses.length, profix);

        PushNewContext();
    }
}
