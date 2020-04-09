pragma solidity >=0.5.0 <0.6.0;

import "./interface/cost/CostInterface.sol";
import "./InternalModule.sol";
import "./TokenChanger.sol";

interface propETHInterface {

    // propETH = _rounds[CurrIdX].propETH;
    function CurrentPropETH() external view returns (uint256);
}


contract Cost is CostInterface, InternalModule {


    uint256 public _costProp = 5;

    propETHInterface _propInc;

    constructor(propETHInterface propInterface) public {
        _propInc = propInterface;
    }

    function CurrentCostProp() external view returns (uint256) {
        return _propInc.CurrentPropETH();
    }

    function DepositedCost(uint256 value) external view returns (uint256) {
        return ( ( value * _costProp / 100 ) * _propInc.CurrentPropETH() ) / 1 ether;
    }

    function WithdrawCost(uint256 value) external view returns (uint256) {
        return ( ( value * _costProp / 100 ) * _propInc.CurrentPropETH() ) / 1 ether;
    }

    function SetCostProp(uint256 newProp) external OwnerOnly {
        _costProp = newProp;
    }
}
