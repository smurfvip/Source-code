pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/token/ERC20Interface.sol";

    {

    address public _managerAssetsPoolAddress;
    address public _nodeAssetsPoolAddress;

    address payable public _nomalAddress = address(0x71F22DeFB5F1bBA92B961be2A91f5D23005C83C5);
    address payable public _devTeamAddress = address(0xc9B73c2DaB657Eb29fFB0b19407c38Bf285e91d2);

    /// Members ///
    struct ChangeRound {
        uint8   roundID;
        uint256 totalToken;
        uint256 propETH;
        uint256 changed;
    }

    ChangeRound[] public _rounds;

    bool public _genesisRoundSuccess = false;
    uint256 _heydayChangedTotalValue = 0;

    ERC20Interface _ERC20Inc;

    uint8 public CurrIdX = 0;

    uint256 public _changeMinLimit = 0.01 ether;

    uint256 public _propETH;

    event Log_ChangedToken(address indexed owner, uint256 indexed ethValue, uint256 tokenValue, uint256 time);

    constructor(
        ERC20Interface erc20inc,
        address _mAddress,
        address _nodeAddress
    ) public {

        _ERC20Inc = erc20inc;
        _managerAssetsPoolAddress = _mAddress;
        _nodeAssetsPoolAddress = _nodeAddress;

        _propETH = 10000 ether;

        _rounds.push( ChangeRound( 1, 3000000 ether, 10000 ether, 0 ) );
        _rounds.push( ChangeRound( 2, 3000000 ether,  8000 ether, 0 ) );
        _rounds.push( ChangeRound( 3, 3000000 ether,  6000 ether, 0 ) );
        _rounds.push( ChangeRound( 4, 3000000 ether,  4000 ether, 0 ) );
    }

    function CurrentPropETH() external view returns (uint256) {
        return _propETH;
    }

    function CurrentHeyDayChagneProp() public view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        uint256 readBrunValue = _ERC20Inc.totalSupply() - _ERC20Inc.balanceOf(address(_ERC20Inc)) - 12000000 ether;

        ChangeRound memory latestRound = _rounds[_rounds.length - 1];

        uint256 propCount = readBrunValue / 200000 ether;

        uint256 propETH = latestRound.propETH / (100 + propCount) * 100;

        if ( propETH < 100 ether ) {
            propETH = 100 ether;
        } else {
            /// INT
            propETH = (propETH / 1 ether) * 1 ether;
        }

        return (5, _ERC20Inc.balanceOf(address(_ERC20Inc)), propETH, _heydayChangedTotalValue);
    }

    function ChangeRoundAt(uint8 rid) external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        return (
            _rounds[rid].roundID,
            _rounds[rid].totalToken,
            _rounds[rid].propETH,
            _rounds[rid].changed
        );

    }

    function CurrentRound() external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed) {

        if ( CurrIdX >= _rounds.length ) {
            return CurrentHeyDayChagneProp();
        }

        return (
            _rounds[CurrIdX].roundID,
            _rounds[CurrIdX].totalToken,
            _rounds[CurrIdX].propETH,
            _rounds[CurrIdX].changed
        );

    }

    function RoundCount() external view returns (uint256) {
        return _rounds.length;
    }

    function DoChangeToken() external payable DAODefense {

        require( msg.value >= _changeMinLimit, "TC_ERR_001" );
        require( msg.value % _changeMinLimit == 0, "TC_ERR_002" );

        if ( !_genesisRoundSuccess ) {

            require( CurrIdX < _rounds.length, "TC_ERR_006");
            ChangeRound storage currRound = _rounds[CurrIdX];

            uint256 minLimitProp = currRound.propETH / ( 1 ether / _changeMinLimit );
            uint256 ctoken = (msg.value / _changeMinLimit) * minLimitProp;

            require ( currRound.changed + ctoken <= currRound.totalToken, "TC_ERR_003" );

            _ERC20Inc.MoveToken( address(_ERC20Inc), msg.sender, ctoken );

            _managerAssetsPoolAddress.call.value(msg.value * 20 / 100)(abi.encode(0x0));
            _nodeAssetsPoolAddress.call.value( msg.value * 30 / 100 )(abi.encode(0x0));

            _nomalAddress.transfer( msg.value * 30 / 100 );
            _devTeamAddress.transfer( address(this).balance ); /// all delta balance

            /// (address indexed owner, uint256 indexed ethValue, uint256 tokenValue, uint256 time);
            emit Log_ChangedToken( msg.sender, msg.value, ctoken, now );

            if ( (currRound.changed + ctoken + minLimitProp) >= currRound.totalToken ) {

                CurrIdX++;

                if ( CurrIdX >= _rounds.length ) {
                    _genesisRoundSuccess = true;
                } else {
                    _propETH = _rounds[CurrIdX].propETH;
                }

            }

            currRound.changed += ctoken;

        } else {

            /// heyday round
            /// uint8 roundID, uint256 total, uint256 prop, uint256 changed
            (,,_propETH,) = CurrentHeyDayChagneProp();

            uint256 minLimitProp = _propETH / ( 1 ether / _changeMinLimit );
            uint256 ctoken = (msg.value / _changeMinLimit) * minLimitProp;

            _ERC20Inc.MoveToken( address(_ERC20Inc), msg.sender, ctoken );

            _managerAssetsPoolAddress.call.value(msg.value * 20 / 100)(abi.encode(0x0));
            _nodeAssetsPoolAddress.call.value( msg.value * 30 / 100 )(abi.encode(0x0));

            _nomalAddress.transfer( msg.value * 30 / 100 );
            _devTeamAddress.transfer( address(this).balance ); /// all delta balance

            //(address indexed owner, uint256 indexed ethValue, uint256 tokenValue, uint256 time);
            emit Log_ChangedToken( msg.sender, msg.value, ctoken, now );

            _heydayChangedTotalValue += ctoken;
        }

    }

    function SetMinLimit( uint256 limit ) external OwnerOnly {
        _changeMinLimit = limit;
    }

    function () external payable {}
}
