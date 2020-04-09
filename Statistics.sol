pragma solidity >=0.5.0 <0.6.0;


import "./InternalModule.sol";

   {

    mapping(address => uint256) _staticProfixTotalMapping;

    mapping(address => uint256) _dynamicProfixTotalMapping;

    mapping(address => bool) _playerAddresses;

    uint256 public JoinedPlayerTotalCount = 0;

    uint256 public JoinedGameTotalCount = 0;

    uint256 public AllWithdrawEtherTotalCount = 0;

    uint256 public WinnerCount = 0;

    function GetStaticProfitTotalAmount() external view returns (uint256) {
        return _staticProfixTotalMapping[msg.sender];
    }

    function GetDynamicProfitTotalAmount() external view returns (uint256) {
        return _dynamicProfixTotalMapping[msg.sender];
    }

    function AddStaticTotalAmount( address player, uint256 value ) external APIMethod {
        _staticProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    function AddDynamicTotalAmount( address player, uint256 value ) external APIMethod {
        _dynamicProfixTotalMapping[player] += value;
        AllWithdrawEtherTotalCount += value;
    }

    function AddWinnerCount() external APIMethod {
        WinnerCount++;
    }
}
