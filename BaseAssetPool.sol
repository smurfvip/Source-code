pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/lib_math.sol";

contract BaseAssetPool is InternalModule {

    uint256 public _totalEther;
    uint256 public _realBalance;


    mapping ( address => uint256 ) _withdrawMapping;

    event Log_WithdrawHistory(address indexed owner, uint256 indexed time, uint256 indexed value);


    function AddWithdrawValue(address owner, uint256 value) internal {
        _withdrawMapping[owner] += value;
    }

    function PushNewContext() internal {
        _realBalance = 0;
    }

    function MyProfix() external view returns (uint256) {
        return _withdrawMapping[msg.sender];
    }


    function WithdrawProfix() external DAODefense {

        uint256 value = _withdrawMapping[msg.sender];

        _withdrawMapping[msg.sender] = 0;

        msg.sender.transfer( value );

        emit Log_WithdrawHistory(msg.sender, now, value);
    }

    function () payable external {
        _realBalance += msg.value;
        _totalEther += msg.value;
    }
}
