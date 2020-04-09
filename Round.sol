pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";
import "./interface/recommend/RecommendInterface.sol";
import "./interface/turing/TuringInterface.sol";
import "./interface/cost/CostInterface.sol";
import "./interface/token/ERC20Interface.sol";
import "./interface/levelsub/LevelSubInterface.sol";
import "./interface/luckassetspool/LuckAssetsPoolInterface.sol";
import "./interface/redress/RedressInterface.sol";
import "./interface/statistics/StatisticsInterface.sol";
import "./interface/lib_math.sol";


library DepositedHistory {

    struct DB {

        uint256 currentDepostiTotalAmount;

        mapping (address => DepositedRecord) map;

        mapping (address => EverIn[]) amountInputs;

        mapping (address => Statistics) totalMap;
    }

    struct Statistics {
        bool isExist;
        uint256 totalIn;
        uint256 totalOut;
    }

    struct EverIn {
        uint256 timeOfDayZero;
        uint256 amount;
    }

    struct DepositedRecord {

        /// this frist join this gams's time;
        uint256 createTime;

        /// latest deposit in time to udpate this record. lg. Join
        uint256 latestDepositInTime;

        /// latest withdraw profix time.
        uint256 latestWithdrawTime;

        /// max limit
        uint256 depositMaxLimit;

        /// current
        uint256 currentEther;

        /// withdrawable totl
        uint256 withdrawableTotal;

        /// no withdraw dy profix
        uint256 canWithdrawProfix;

        /// max of gameover multiplier
        uint8 profixMultiplier;
    }

    function MaxProfixDelta( DB storage self, address owner) public view returns (uint256) {

        if ( !isExist(self, owner) ) {
            return 0;
        }

        return (self.map[owner].currentEther * self.map[owner].profixMultiplier) - self.map[owner].withdrawableTotal;
    }

    function isExist( DB storage self, address owner ) public view returns (bool) {
        return self.map[owner].createTime != 0;
    }

    function Create( DB storage self, address owner, uint256 value, uint256 maxlimit, uint8 muler ) public returns (bool) {

        uint256 dayz = lib_math.CurrentDayzeroTime();

        if ( self.map[owner].createTime != 0 ) {
            return false;
        }

        self.map[owner] = DepositedRecord(dayz, dayz, dayz, maxlimit, value, 0, 0, muler);
        self.currentDepostiTotalAmount += value;

        if ( !self.totalMap[owner].isExist ) {
            self.totalMap[owner] = Statistics(true, value, 0);
        } else {
            self.totalMap[owner].totalIn += value;
        }

        self.amountInputs[owner].push( EverIn(lib_math.CurrentDayzeroTime(), value) );

        return true;
    }

    function Clear( DB storage self, address owner) internal {
        self.map[owner].createTime = 0;
        self.map[owner].currentEther = 0;
        self.map[owner].latestDepositInTime = 0;
        self.map[owner].latestWithdrawTime = 0;
        self.map[owner].depositMaxLimit = 0;
        self.map[owner].currentEther = 0;
        self.map[owner].withdrawableTotal = 0;
        self.map[owner].canWithdrawProfix = 0;
        self.map[owner].profixMultiplier = 0;
    }

    function AppendEtherValue( DB storage self, address owner, uint256 appendValue ) public returns (bool) {

        if ( self.map[owner].createTime == 0 ) {
            return false;
        }

        self.map[owner].currentEther += appendValue;
        self.map[owner].latestDepositInTime = now;
        self.currentDepostiTotalAmount += appendValue;
        self.totalMap[owner].totalIn += appendValue;

        EverIn storage lr = self.amountInputs[owner][ self.amountInputs[owner].length - 1 ];

        if ( lr.timeOfDayZero == lib_math.CurrentDayzeroTime() ) {
            lr.amount += appendValue;
        } else {
            self.amountInputs[owner].push( EverIn(lib_math.CurrentDayzeroTime(), lr.amount + appendValue) );
        }

        return true;
    }

    function PushWithdrawableTotalRecord( DB storage self, address owner, uint256 profix ) public returns (bool) {

        if ( self.map[owner].createTime == 0 ) {
            return false;
        }

        self.map[owner].canWithdrawProfix = 0;
        self.map[owner].withdrawableTotal += profix;
        self.map[owner].latestWithdrawTime = lib_math.CurrentDayzeroTime();

        self.totalMap[owner].totalOut += profix;

        if ( self.map[owner].withdrawableTotal > self.map[owner].currentEther * self.map[owner].profixMultiplier ) {
            self.map[owner].withdrawableTotal = self.map[owner].currentEther * self.map[owner].profixMultiplier;
        }

        return true;
    }

    function GetNearestTotoalInput( DB storage self, address owner, uint256 timeOfDayZero) public view returns (uint256) {

        EverIn memory lr = self.amountInputs[owner][self.amountInputs[owner].length - 1 ];

        if ( timeOfDayZero >= lr.timeOfDayZero ) {

            return lr.amount;

        } else {

            for ( uint256 i2 = self.amountInputs[owner].length; i2 >= 1; i2--) {

                uint256 i = i2 - 1;

                if ( self.amountInputs[owner][i].timeOfDayZero <= timeOfDayZero ) {
                    return self.amountInputs[owner][i].amount;
                }
            }
        }

        return 0;
    }
}

   {

    address payable _latestAddress = address(0xeA0C1479752B4A72FA8fF3EF8f3406765655D5f0);

    bool public isBroken = false;

    TuringInterface public _TuringInc;
    RecommendInterface public _RecommendInc;
    ERC20Interface public _ERC20Inc;
    CostInterface public _CostInc;
    LevelSubInterface public _LevelSubInc;
    RedressInterface public _RedressInc;
    StatisticsInterface public _StatisticsInc;
    LuckAssetsPoolInterface public _luckPoolA;
    LuckAssetsPoolInterface public _luckPoolB;

    constructor (

        TuringInterface TuringInc,
        RecommendInterface RecommendInc,
        ERC20Interface ERC20Inc,
        CostInterface CostInc,
        LevelSubInterface LevelSubInc,
        RedressInterface RedressInc,
        StatisticsInterface StatisticsInc,
        LuckAssetsPoolInterface luckPoolA,
        LuckAssetsPoolInterface luckPoolB

    ) public {

        _TuringInc = TuringInc;
        _RecommendInc = RecommendInc;
        _ERC20Inc = ERC20Inc;
        _CostInc = CostInc;
        _LevelSubInc = LevelSubInc;
        _RedressInc = RedressInc;
        _StatisticsInc = StatisticsInc;
        _luckPoolA = luckPoolA;
        _luckPoolB = luckPoolB;

    }

    uint256 public _depositMinLimit = 1 ether;
    uint256 public _depositMaxLimit = 50 ether;
    uint8   public _profixMultiplier = 3;

    uint256[] public _dynamicProfits = [20, 15, 10, 5, 5, 5, 5, 5, 5, 5, 3, 3, 3, 3, 3];

    DepositedHistory.DB private _depostedHistory;
    using DepositedHistory for DepositedHistory.DB;

    uint256 public _beforBrokenedCostProp;

    mapping( address => bool ) _redressableMapping;

    event Log_ProfixHistory(address indexed owner, uint256 indexed value, uint8 indexed ptype, uint256 time);
    event Log_NewDeposited(address indexed owner, uint256 indexed time, uint256 indexed value);
    event Log_NewWinner(address indexed owner, uint256 indexed time, uint256 indexed baseAmount, uint8 mn);
    event Log_WithdrawProfix(address indexed addr, uint256 indexed time, uint256 indexed value, uint256 rvalue);

    modifier OnlyInBrokened() {
        require( isBroken );
        _;
    }

    modifier OnlyInPlaying() {
        require( !isBroken );
        _;
    }

    modifier PauseDisable() {
        require ( !_luckPoolA.NeedPauseGame() );
        _;
    }

    modifier DAODefense() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "DAO_Warning" );
        _;
    }

    function GetEvenInRecord(address owner, uint256 index) external view returns ( uint256 time, uint256 total, uint256 len ) {

        return ( _depostedHistory.amountInputs[owner][index].timeOfDayZero, _depostedHistory.amountInputs[owner][index].amount, _depostedHistory.amountInputs[owner].length );
    }

    function Join() external payable OnlyInPlaying PauseDisable DAODefense {

        _TuringInc.Analysis();

        /// address must be bind recommend relations befor join this game.
        require( _RecommendInc.GetIntroducer(msg.sender) != address(0x0), "E01" );

        require( _TuringInc.GetDepositedLimitCurrentDelta() >= msg.value );
        _TuringInc.SubDepositedLimitCurrent( msg.value );

        require( msg.value >= _depositMinLimit, "E07" );

        uint256 cost = _CostInc.DepositedCost(msg.value);
        require( _ERC20Inc.balanceOf(msg.sender) >= cost, "E08" );
        _ERC20Inc.MoveToken( msg.sender, address(0x0), cost );

        if ( _depostedHistory.isExist(msg.sender) ) {

            DepositedHistory.DepositedRecord memory r = _depostedHistory.map[msg.sender];

            require( msg.value <= r.depositMaxLimit - r.currentEther);

            require( now - r.latestDepositInTime >= lib_math.OneDay() * 2 );

            _depostedHistory.AppendEtherValue(msg.sender, msg.value);

        } else {

            require( msg.value <= _depositMaxLimit );

            _depostedHistory.Create(msg.sender, msg.value, _depositMaxLimit, _profixMultiplier);
        }

        /// push a inputs record
        emit Log_NewDeposited( msg.sender, now, msg.value);

        if ( address(this).balance > 3000 ether ) {
            _TuringInc.PowerOn();
        }

        // transfer ether
        address payable lpiaddrA = address( uint160( address(_luckPoolA) ) );
        address payable lpiaddrB = address( uint160( address(_luckPoolB) ) );

        lpiaddrA.transfer(msg.value * _luckPoolA.InPoolProp() / 100);
        lpiaddrB.transfer(msg.value * _luckPoolB.InPoolProp() / 100);

        _luckPoolA.AddLatestAddress(msg.sender, msg.value);
        _luckPoolB.AddLatestAddress(msg.sender, msg.value);

        _RecommendInc.MarkValid( msg.sender, msg.value );

        return ;
    }

    function CurrentDepsitedTotalAmount() external view returns (uint256) {
        return _depostedHistory.currentDepostiTotalAmount;
    }

    function CurrentCanWithdrawProfix(address owner) public view returns (uint256 st, uint256 dy) {

        if ( !_depostedHistory.isExist(owner) ) {
            return (0, 0);
        }

        DepositedHistory.DepositedRecord memory r = _depostedHistory.map[owner];

        uint256 deltaDays = (lib_math.CurrentDayzeroTime() - r.latestWithdrawTime) / lib_math.OneDay();

        uint256 staticTotal = 0;

        for (uint256 i = 0; i < deltaDays; i++) {

            uint256 cday = lib_math.CurrentDayzeroTime() - (i * lib_math.OneDay());

            uint256 dp = _TuringInc.GetProfitPropBytime( cday );

            staticTotal = staticTotal + (_depostedHistory.GetNearestTotoalInput(owner, cday) * dp / 1000);
        }

        return (staticTotal, r.canWithdrawProfix);
    }

    function WithdrawProfix() external OnlyInPlaying PauseDisable DAODefense {

        DepositedHistory.DepositedRecord memory r = _depostedHistory.map[msg.sender];

        (uint256 stProfix, uint256 dyProfix) = CurrentCanWithdrawProfix(msg.sender);
        uint256 totalProfix =  stProfix + dyProfix;

        if ( _depostedHistory.MaxProfixDelta(msg.sender) < totalProfix ) {

            totalProfix = _depostedHistory.MaxProfixDelta(msg.sender);

            _StatisticsInc.AddWinnerCount();

            _depostedHistory.Clear(msg.sender);

            _depostedHistory.totalMap[msg.sender].totalOut += totalProfix;

            emit Log_NewWinner(msg.sender, now, r.currentEther, r.profixMultiplier);

        } else {
            _depostedHistory.PushWithdrawableTotalRecord(msg.sender, totalProfix);
        }

        uint256 realStProfix = totalProfix * _TuringInc.GetCurrentWithrawThreshold() / 100;
        uint256 cost = _CostInc.WithdrawCost( totalProfix );
        require( _ERC20Inc.balanceOf(msg.sender) >= cost, "E08" );
        _ERC20Inc.MoveToken( msg.sender, address(0x0), cost );
        msg.sender.transfer(realStProfix);

        emit Log_ProfixHistory(msg.sender, stProfix * _TuringInc.GetCurrentWithrawThreshold() / 100, 40, now);
        emit Log_WithdrawProfix(msg.sender, now, totalProfix, realStProfix);


        if ( stProfix <= 0 ) {
            return;
        }

        _StatisticsInc.AddStaticTotalAmount(msg.sender, stProfix);

        uint256 senderDepositedValue = r.currentEther;
        uint256 dyProfixBaseValue = stProfix;
        address parentAddr = msg.sender;
        for ( uint256 i = 0; i < _dynamicProfits.length; i++ ) {

            parentAddr = _RecommendInc.GetIntroducer(parentAddr);

            if ( parentAddr == address(0x0) ) {

                break;
            }

            uint256 pdmcount = _RecommendInc.DirectValidMembersCount( parentAddr );

            if ( pdmcount >= 6 || _LevelSubInc.LevelOf(parentAddr) > 0 ) {
                pdmcount = _dynamicProfits.length;
            }

            if ( (i + 1) > pdmcount ) {
                continue;
            }

            if ( _depostedHistory.isExist(parentAddr) ) {

                uint256 parentDyProfix = dyProfixBaseValue * _dynamicProfits[i] / 100;

                if ( senderDepositedValue > _depostedHistory.map[parentAddr].currentEther && _depostedHistory.map[parentAddr].currentEther < 30 ether ) {
                    parentDyProfix = parentDyProfix * ( _depostedHistory.map[parentAddr].currentEther * 100 / senderDepositedValue ) / 100;
                }

                emit Log_ProfixHistory(parentAddr, parentDyProfix, uint8(i), now);
                _depostedHistory.map[parentAddr].canWithdrawProfix += parentDyProfix;
                _StatisticsInc.AddDynamicTotalAmount(parentAddr, parentDyProfix);
            }
        }

        uint256 len = 0;
        address[] memory addrs;
        uint256[] memory profits;
        (len, addrs, profits) = _LevelSubInc.ProfitHandle( msg.sender, stProfix );
        for ( uint j = 0; j < len; j++ ) {

            if ( addrs[j] == address(0x0) ) {
                continue ;
            }

            if ( len - j < 3 ) {
                emit Log_ProfixHistory(addrs[j], profits[j], uint8( 30 + _LevelSubInc.LevelOf(addrs[j])), now);
            } else {
                emit Log_ProfixHistory(addrs[j], profits[j], uint8( 20 + _LevelSubInc.LevelOf(addrs[j])), now);
            }

            _depostedHistory.map[addrs[j]].canWithdrawProfix += profits[j];
            _StatisticsInc.AddDynamicTotalAmount(addrs[j], profits[j]);
        }
    }

    function TotalInOutAmount() external view returns (uint256 inEther, uint256 outEther) {
        return ( _depostedHistory.totalMap[msg.sender].totalIn, _depostedHistory.totalMap[msg.sender].totalOut );
    }

    function GetRedressInfo() external view OnlyInBrokened returns (uint256 total, bool withdrawable) {

        DepositedHistory.Statistics memory r = _depostedHistory.totalMap[msg.sender];

        if ( r.totalOut >= r.totalIn ) {
            return (0, false);
        }

        uint256 subEther = r.totalIn - r.totalOut;

        uint256 redtotal = (subEther * _beforBrokenedCostProp / 1 ether);

        return (redtotal, _redressableMapping[msg.sender]);
    }

    function DrawRedress() external OnlyInBrokened returns (bool) {

        DepositedHistory.Statistics memory r = _depostedHistory.totalMap[msg.sender];

        if ( r.totalOut >= r.totalIn ) {
            return false;
        }

        if ( !_redressableMapping[msg.sender] ) {

            _redressableMapping[msg.sender] = true;

            uint256 subEther = r.totalIn - r.totalOut;

            uint256 redtotal = (subEther * _beforBrokenedCostProp / 1 ether);

            _RedressInc.AddRedress(msg.sender, redtotal);

            return true;
        }

        return false;
    }

    function GetCurrentGameStatus() external view returns (/// this frist join this gams's time;
        uint256 createTime,
        uint256 latestDepositInTime,
        uint256 latestWithdrawTime,
        uint256 depositMaxLimit,
        uint256 currentEther,
        uint256 withdrawableTotal,
        uint256 canWithdrawProfix,
        uint8 profixMultiplier
    ) {
        createTime = _depostedHistory.map[msg.sender].createTime;
        latestDepositInTime = _depostedHistory.map[msg.sender].latestDepositInTime;
        latestWithdrawTime = _depostedHistory.map[msg.sender].latestWithdrawTime;
        depositMaxLimit = _depostedHistory.map[msg.sender].depositMaxLimit;
        currentEther = _depostedHistory.map[msg.sender].currentEther;
        withdrawableTotal = _depostedHistory.map[msg.sender].withdrawableTotal;
        canWithdrawProfix = _depostedHistory.map[msg.sender].canWithdrawProfix;
        profixMultiplier = _depostedHistory.map[msg.sender].profixMultiplier;
    }

    function Activity(address _recommer, bytes6 shortCode) external {
        _RecommendInc.BindEx(msg.sender, _recommer, shortCode);
    }

         {

        if ( address(this).balance < 100 ether ) {

            isBroken = true;

            _beforBrokenedCostProp = _CostInc.CurrentCostProp();

            _latestAddress.transfer( address(this).balance );

            _luckPoolB.GameOver();

        } else {

            _luckPoolA.Reboot();
        }

    }

    function Redeem() external OnlyInPlaying PauseDisable DAODefense {

        DepositedHistory.Statistics storage tr = _depostedHistory.totalMap[msg.sender];

        DepositedHistory.DepositedRecord storage r = _depostedHistory.map[msg.sender];

        require(now - r.latestDepositInTime >= lib_math.OneDay() * 90 );

        require(tr.totalIn > tr.totalOut);

        uint256 deltaEther = tr.totalIn - tr.totalOut;

        require(address(this).balance >= deltaEther);

        _depostedHistory.Clear(msg.sender);

        tr.totalOut = tr.totalIn;

        msg.sender.transfer(deltaEther);
    }

    function SetProfixMultiplier(uint8 m) external OwnerOnly {
        _profixMultiplier = m;
    }

    function SetDepositLimit(uint256 min, uint256 max) external OwnerOnly {
        _depositMinLimit = min;
        _depositMaxLimit = max;
    }

    function () payable external {}
}
