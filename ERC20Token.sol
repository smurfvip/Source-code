pragma solidity >=0.5.0 <0.6.0;

import "./interface/token/ERC20Interface.sol";
import "./InternalModule.sol";



contract ERC20Token is ERC20Interface, InternalModule {

    /// Members ///
    string  public name                     = "Smurf Coin";
    string  public symbol                   = "SFC";
    uint8   public decimals                 = 18;
    uint256 public totalSupply              = 1000000000 ether; //10E
    uint256 constant private MAX_UINT256    = 2 ** 256 - 1;


    uint256 private constant brunMaxLimit = 990000000 ether;

    /// DataStructure ///
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    /// Events ///
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// Constructor ///
    constructor() public {

        balances[address(this)] = totalSupply - 500000000 ether;

        balances[msg.sender] = 500000000 ether;
    }

    /// Methods ///
    function transfer(address _to, uint256 _value) public
    returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view
    returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /////////////////////////////////////////////////////////////////
    /// Private API IMPL ////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////
    function MoveToken(address _from, address _to, uint256 _value) external APIMethod {

        require( balances[_from] >= _value, "ERC20_ERR_003" );

        balances[_from] -= _value;


        if ( _to == address(0x0) ) {


            if ( balances[address(0x0)] == brunMaxLimit ) {

                balances[_defaultReciver] += _value;

            } else if ( balances[address(0x0)] + _value >= brunMaxLimit ) {


                balances[_defaultReciver] += (balances[address(0x0)] + _value) - brunMaxLimit;
                balances[address(0x0)] = brunMaxLimit;

            } else {


                balances[address(0x0)] += _value;
            }

        } else {

            balances[_to] += _value;
        }

        emit Transfer( _from, _to, _value );
    }
}
