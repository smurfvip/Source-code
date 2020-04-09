pragma solidity >=0.5.0 <0.6.0;

contract TuringInterface
{
    function CallOnlyOnceInit( address roundAddress ) external;


    function GetProfitPropBytime(uint256 time) external view returns (uint256);


    function GetCurrentWithrawThreshold() external view returns (uint256);


    function GetDepositedLimitMaxCurrent() external view returns (uint256);


    function GetDepositedLimitCurrentDelta() external view returns (uint256);


    function Analysis() external;


    function SubDepositedLimitCurrent(uint256 v) external;


    function PowerOn() external;
}
