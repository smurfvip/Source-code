pragma solidity >=0.5.0 <0.6.0;

import "./BaseAssetPool.sol";
import "./interface/levelsub/LevelSubInterface.sol";

// function ManagerListOfLevel( uint256 lv ) external view returns (address[] memory addrs);
   {

    uint256 public _latestBonusTime;

    LevelSubInterface public _LVInc;

    uint256[] public _bonusProfits = [0, 25, 25, 25, 25];

    event Log_BonusDetail(address indexed owner, uint256 indexed time, uint256 indexed value);
    event Log_Bonus(uint256 indexed time, uint256 totalCount, uint256 totalValue);

    constructor(LevelSubInterface lvinc) public {
        _LVInc = lvinc;
        _latestBonusTime = now;
    }

    function Status() external view returns (
        uint256 balance,
        uint256 c1,
        uint256 c2,
        uint256 c3,
        uint256 c4,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 p4,
        uint256 lbt,
        bool canBonus
    ) {
        balance = _realBalance;

        c1 = _LVInc.ManagerListOfLevel(1).length;
        c2 = _LVInc.ManagerListOfLevel(2).length;
        c3 = _LVInc.ManagerListOfLevel(3).length;
        c4 = _LVInc.ManagerListOfLevel(4).length;

        p1 = (balance * _bonusProfits[1] / 100) / c1;
        p2 = (balance * _bonusProfits[2] / 100) / c2;
        p3 = (balance * _bonusProfits[3] / 100) / c3;
        p4 = (balance * _bonusProfits[4] / 100) / c4;

        lbt = _latestBonusTime;

        canBonus = (now - lbt) >= lib_math.OneDay() * 7;
    }

    function DoBonus() external OwnerOnly {

        uint256 bonusAmount = _realBalance;

        uint256 totalCount = 0;

        // loop 1 ... 4
        for ( uint l = 1; l < 5; l++ ) {

            address[] memory lvAddresses = _LVInc.ManagerListOfLevel(l);

            if ( lvAddresses.length == 0 ) {
                continue;
            }

            uint256 profix = (bonusAmount * _bonusProfits[l] / 100) / lvAddresses.length;

            totalCount += lvAddresses.length;

            for ( uint i = 0; i < lvAddresses.length; i++ ) {

                AddWithdrawValue(lvAddresses[i], profix);

                emit Log_BonusDetail(lvAddresses[i], now, profix);
            }

        }

        emit Log_Bonus(now, totalCount, bonusAmount);

        PushNewContext();
    }
}
