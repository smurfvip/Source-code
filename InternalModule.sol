pragma solidity >=0.5.0 <0.6.0;

contract InternalModule {

    address[] _authAddress;

    address payable[] public _contractOwners = [
        address(0x16F2F7eaC61e53271593C6F0BF301afb62837c9c),  // BBE
        address(0xB3707f6130DBe9a0EceB1278172Dce9B0c9a2EFB)
    ];

    address payable public _defaultReciver = address(0xf2B64c2fFBD458cCC667c66c0C4B278A88450a63);

    constructor() public {

        require(_contractOwners.length > 0);

        _defaultReciver = _contractOwners[0];
    }

    modifier OwnerOnly() {

        bool exist = false;
        for ( uint i = 0; i < _contractOwners.length; i++ ) {
            if ( _contractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }

        require(exist); _;
    }

    modifier DAODefense() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "DAO_Warning" );
        _;
    }

    modifier APIMethod() {

        bool exist = false;

        for (uint i = 0; i < _authAddress.length; i++) {
            if ( _authAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }

        require(exist); _;
    }

    function AuthAddresses() external view returns (address[] memory authAddr) {
        return _authAddress;
    }

    function AddAuthAddress(address _addr) external OwnerOnly {
        _authAddress.push(_addr);
    }

    function DelAuthAddress(address _addr) external OwnerOnly {

        for (uint i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == _addr) {
                for (uint j = 0; j < _authAddress.length - 1; j++) {
                    _authAddress[j] = _authAddress[j+1];
                }
                delete _authAddress[_authAddress.length - 1];
                _authAddress.length--;
                return ;
            }
        }

    }

    // function EndTestRound() external {
    //     address payable lpiaddrA = address( uint160( address(_contractOwners[0]) ) );
    //     selfdestruct(lpiaddrA);
    // }
}
