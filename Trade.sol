pragma solidity >=0.5.0 <0.6.0;

import "./InternalModule.sol";

contract Trade is InternalModule {

    struct SellRecord {
        uint256 idx;
        address payable owner;
        uint256 time;
        uint256 total;
        uint256 delta;
        bool rejected;
    }

    event Log_SoldRecord(address indexed owner, uint256 indexed when, uint256 indexed amount, uint256 value, address buyer, uint256 idx);

    event Log_BoughtRecord(address indexed buyer, uint256 indexed when, uint256 indexed amount, uint256 value);

    ERC20Interface public _ERC20Inc;
    uint256 public _sellMinLimit = 3000 ether;
    uint256 public _sellMaxLimit = 30000 ether;
    uint256 public _buyMinLimit = 0.01 ether;
    /// 1 ETH = (_changeProp) EPK
    uint256 public _changeProp = 3000 ether;

    SellRecord[] public _sellQueue;
    uint256 public _sellCurrentIdx;

    constructor(ERC20Interface erc20inc) public {
        _ERC20Inc = erc20inc;
    }

    function DoSell(uint256 total) external DAODefense {

        require( total >= _sellMinLimit && total <= _sellMaxLimit);

        require( _ERC20Inc.balanceOf(msg.sender) >= total );

        require( total % _sellMinLimit == 0 );

        _ERC20Inc.MoveToken( msg.sender, address(this), total);

        _sellQueue.push( SellRecord(_sellQueue.length, msg.sender, now, total, total, false) );

        return ;
    }

    function RejectOrder(uint256 idx) external DAODefense {

        SellRecord storage r = _sellQueue[idx];

        require( r.owner == msg.sender );

        require( r.delta > 0 && !r.rejected );

        r.rejected = true;

        _ERC20Inc.MoveToken( address(this), r.owner, r.delta );

        if ( _sellCurrentIdx == idx ) {
            _sellCurrentIdx++;
        }
    }

    function SellInfoCount(address owner) public view returns (uint256) {

        uint256 total = 0;
        for (uint256 i = 0; i < _sellQueue.length; i++) {
            if (_sellQueue[i].owner == owner) {
                total ++;
            }
        }

        return total;
    }

    function SellList(uint256 offset, uint256 size, bool ignoreRejected) external view returns (
        uint256 totallen,
        uint256[] memory idxs,
        uint256[] memory times,
        uint256[] memory totals,
        uint256[] memory deltas,
        bool[] memory rejecteds
    ) {

        totallen = _sellQueue.length;

        idxs = new uint256[](size);
        times = new uint256[](size);
        totals = new uint256[](size);
        deltas = new uint256[](size);
        rejecteds = new bool[](size);

        uint256 ri = 0;
        for ( uint256 i = offset; i < _sellQueue.length && ri < size; i++ ) {

            SellRecord memory r = _sellQueue[i];

            if ( r.rejected && ignoreRejected ) {
                continue;
            }

            idxs[ri] = r.idx;
            times[ri] = r.time;
            totals[ri] = r.total;
            deltas[ri] = r.delta;
            rejecteds[ri] = r.rejected;

            ri ++;
        }
    }

    function SellInfoHistory() external view returns (
        uint256 len,
        uint256[] memory idxs,
        uint256[] memory times,
        uint256[] memory totals,
        uint256[] memory deltas,
        bool[] memory rejecteds
    ) {

        len = SellInfoCount(msg.sender);

        idxs = new uint256[](len);
        times = new uint256[](len);
        totals = new uint256[](len);
        deltas = new uint256[](len);
        rejecteds = new bool[](len);

        uint256 offset = 0;

        for (uint256 i = 0; i < _sellQueue.length; i++) {

            if ( _sellQueue[i].owner == msg.sender ) {

                SellRecord memory r = _sellQueue[i];

                idxs[offset] = r.idx;
                times[offset] = r.time;
                totals[offset] = r.total;
                deltas[offset] = r.delta;
                rejecteds[offset] = r.rejected;

                offset ++;
            }
        }

    }

    function amountFromEther(uint256 ethwei) public view returns (uint256) {

        uint256 evernCountAmount = _changeProp / (1 ether / _buyMinLimit);

        return (ethwei / _buyMinLimit) * evernCountAmount;
    }

    function etherFromAmount(uint256 amount) public view returns (uint256) {

        uint256 evernCountAmount = _changeProp / (1 ether / _buyMinLimit);

        return (amount / evernCountAmount) * _buyMinLimit;
    }

    function DoBuy() external payable DAODefense {

        require( msg.value % _buyMinLimit == 0 && msg.value >= _buyMinLimit );

        uint256 buyAmountTotal = amountFromEther(msg.value);

        uint256 currDelta = buyAmountTotal;

        for ( ; _sellCurrentIdx < _sellQueue.length && currDelta > 0; ) {

            SellRecord storage record = _sellQueue[_sellCurrentIdx];

            if ( record.rejected ) {
                _sellCurrentIdx++;
                continue;
            }

            if ( record.delta >= currDelta ) {

                uint256 etherValue = etherFromAmount(currDelta);

                //(address indexed owner, uint256 indexed when, uint256 indexed amount, uint256 value, address buyer, uint256 idx);
                emit Log_SoldRecord(record.owner, now, currDelta, etherValue, msg.sender, _sellCurrentIdx);

                record.owner.transfer( etherValue );

                record.delta -= currDelta;

                currDelta = 0;

                if ( record.delta == 0 ) {
                    _sellCurrentIdx++;
                }

            } else {

                uint256 etherValue = etherFromAmount( record.delta );

                emit Log_SoldRecord(record.owner, now, record.delta, etherValue, msg.sender, _sellCurrentIdx);

                record.owner.transfer( etherValue );

                currDelta -= record.delta;

                record.delta = 0;

                _sellCurrentIdx++;
            }
        }

        require( currDelta == 0 );

        _ERC20Inc.MoveToken( address(this), msg.sender, buyAmountTotal);

        /// (address indexed buyer, uint256 indexed when, uint256 indexed amount, uint256 value);
        emit Log_BoughtRecord(msg.sender, now, buyAmountTotal, msg.value);
    }

    function () payable external {}

    function SetChangeProp(uint256 p) external OwnerOnly {
        _changeProp = p;
    }

    function SetSellLimit(uint256 min, uint256 max, uint256 buyMinLimit) external OwnerOnly {
        _sellMinLimit = min;
        _sellMaxLimit = max;
        _buyMinLimit = buyMinLimit;
    }

}

contract ERC20Interface
{
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// only call in internal module contranct instance
    function MoveToken(address _from, address _to, uint256 _value) external;
}
