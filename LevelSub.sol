pragma solidity >=0.5.0 <0.6.0;

import "./interface/levelsub/LevelSubInterface.sol";
import "./interface/recommend/RecommendInterface.sol";
import "./InternalModule.sol";


contract LevelSub is LevelSubInterface, InternalModule {

    RecommendInterface  private _recommendInf;


    uint256             public _searchReommendDepth = 15;

    uint256             public _searchLvLayerDepth = 1024;

    uint256[]           public _subProfits = [0, 5, 5, 5, 5];

    uint256             public _equalLvProp = 10;

    uint256             public _equalLvMaxLimit = 3;

    uint256             public _equalLvSearchDepth = 10;

    uint256             public _paymentLv2Prices = 200 ether;

    address payable     public _defaultReciver = address(0x40364eC2F63bB958759ACC05433CF4F84e677b7d);

    address []          public _merAddressList;

    mapping ( address => uint256 ) _ownerLevelsMapping;

    mapping (uint256 => address[]) public _managerLevelList;

    address []          public _noders;

    uint256             public _paymentedCount = 0;

    constructor( RecommendInterface recomm ) public {

        _recommendInf = recomm;

        _ownerLevelsMapping[address(0x12dF19B8C1Da2F44C47A1E0Fb70d2452e8d57DFc)] = 3;
        _ownerLevelsMapping[address(0x37650dC8C9b5EFb4f0f4Ab6f3C6C64c00cce41a5)] = 2;
    }

    function PaymentToUpgradeNoderL2() external payable DAODefense {

        require( _paymentedCount < 13);
        require( !AddressIsNoder(msg.sender) );
        require( msg.value >= _paymentLv2Prices );


        if ( _ownerLevelsMapping[msg.sender] > 0 && _ownerLevelsMapping[msg.sender] < 2  ) {

            uint256 currLv = _ownerLevelsMapping[msg.sender];

            address[] storage lvList = _managerLevelList[currLv];

            for ( uint256 i = 0; i < lvList.length; i++ ) {

                if ( lvList[i] == msg.sender ) {

                    for ( uint256 j = i; j < lvList.length - 1; j++ ) {
                        lvList[j] = lvList[j+1];
                    }

                    delete lvList[ lvList.length - 1 ];
                    lvList.length--;

                    break;
                }
            }

            _ownerLevelsMapping[msg.sender] = 2;
            _managerLevelList[2].push(msg.sender);

        } else if ( _ownerLevelsMapping[msg.sender] == 0 ) {

            _ownerLevelsMapping[msg.sender] = 2;
            _managerLevelList[2].push(msg.sender);
            _merAddressList.push(msg.sender);
        }


        _defaultReciver.transfer(msg.value);
        _noders.push(msg.sender);
        _paymentedCount++;
    }

    function GetLevelSubValues() external view returns (uint256[] memory _values) {
        return _subProfits;
    }

    function LevelOf( address _owner ) public view returns (uint256 lv) {
        return _ownerLevelsMapping[_owner];
    }

    function Noders() external view returns (address[] memory) {
        return _noders;
    }

    function AddressIsNoder(address sender) public view returns (bool) {

        for ( uint i = 0; i < _noders.length; i++) {
            if ( _noders[i] == sender ) {
                return true;
            }
        }

        return false;
    }

    function ManagerListOfLevel( uint256 lv ) external view returns (address[] memory addrs) {
        return _managerLevelList[lv];
    }


    function CanUpgradeLv( address _rootAddr ) public view returns (int) {


        require( _ownerLevelsMapping[_rootAddr] < _subProfits.length - 1, "Level Is Max" );

        uint256 effCount = 0;
        address[] memory referees;


        if ( _ownerLevelsMapping[_rootAddr] == 0 ) {


            if ( _recommendInf.InvestTotalEtherOf(_rootAddr) >= 50 ether ) {
                return 1;
            }


            referees = _recommendInf.RecommendList(_rootAddr, 0);

            for (uint i = 0; i < referees.length; i++) {

                if ( _recommendInf.IsValidMember( referees[i] ) ) {

                    //PROD VALUE
                    if ( ++effCount >= 6 ) {
                        break;
                    }
                }
            }

            //PROD VALUE
            if ( effCount < 6 ) {

                return -1;
            }


            //PROD VALUE
            if ( _recommendInf.InvestTotalEtherOf(_rootAddr) < 20 ether ) {

                return -2;
            }


            //PROD VALUE
            if ( _recommendInf.ValidMembersCountOf(_rootAddr) < 100 ) {
                return -3;
            }

            return 1;
        }
        // Lv.n(n != 0) -> Lv.(n + 1)

        else {


            uint256 targetLv = _ownerLevelsMapping[_rootAddr] + 1;

            referees = _recommendInf.RecommendList(_rootAddr, 0);

            uint256 levelUpEffCount = 2;
            if ( targetLv > 2) {
                levelUpEffCount = 3;
            }

            for ( uint i = 0; i < referees.length && effCount < levelUpEffCount; i++ ) {


                if ( LevelOf( referees[i] ) >= targetLv - 1 ) {

                    effCount ++;
                    continue;

                } else {

                    bool finded = false;
                    for ( uint d = 0; d < _searchReommendDepth - 1 && !finded; d++ ) {

                        address[] memory grandchildren = _recommendInf.RecommendList( referees[i], d );

                        for ( uint256 z = 0; z < grandchildren.length && !finded; z++ ) {

                            if ( LevelOf( grandchildren[z] ) >= targetLv - 1 ) {
                                finded = true;
                            }

                        }
                    }

                    if ( finded ) {
                        effCount ++;
                    }
                }
            }

            if ( effCount >= levelUpEffCount ) {
                return int(targetLv);
            } else {
                return -1;
            }

        }
    }

    function DoUpgradeLv( ) external returns (uint256) {

        int256 canMakeToTargetLv = CanUpgradeLv(msg.sender);

        require(canMakeToTargetLv > 0);

        if ( canMakeToTargetLv > 1 ) {

            uint256 currLv = _ownerLevelsMapping[msg.sender];

            address[] storage lvList = _managerLevelList[currLv];

            for ( uint256 i = 0; i < lvList.length; i++ ) {

                if ( lvList[i] == msg.sender ) {

                    for ( uint256 j = i; j < lvList.length - 1; j++ ) {
                        lvList[j] = lvList[j+1];
                    }

                    delete lvList[ lvList.length - 1 ];
                    lvList.length--;
                    break;
                }
            }
        }

        _ownerLevelsMapping[msg.sender] = uint256(canMakeToTargetLv);

        _managerLevelList[uint256(canMakeToTargetLv)].push(msg.sender);

        return _ownerLevelsMapping[msg.sender];
    }


    function ProfitHandle( address _owner, uint256 _amount ) external view
    returns ( uint256 len, address[] memory addrs, uint256[] memory profits ) {

        uint256[] memory tempProfits = _subProfits;

        address parent = _recommendInf.GetIntroducer(_owner);

        if ( parent == address(0x0) ) {
            return (0, new address[](0), new uint256[](0));
        }

        /// V1
        // len = _subProfits.length;
        // addrs = new address[](len);
        // profits = new uint256[](len);

        len = _subProfits.length + _equalLvMaxLimit;
        addrs = new address[](len);
        profits = new uint256[](len);

        uint256 currlv = 0;
        uint256 plv = _ownerLevelsMapping[parent];

        address nearestAddr;
        uint256 nearestProfit;


        for ( uint i = 0; i < _searchLvLayerDepth; i++ ) {


            if ( plv > currlv && tempProfits[plv] > 0 ) {

                uint256 psum = 0;

                for ( uint x = plv; x > 0; x-- ) {

                    psum += tempProfits[x];

                    tempProfits[x] = 0;
                }

                if ( psum > 0 ) {

                    if ( nearestAddr == address(0x0) && plv > 1 ) {
                        nearestAddr = parent;
                        nearestProfit = (_amount * psum) / 100;
                    }

                    addrs[plv] = parent;
                    profits[plv] = (_amount * psum) / 100;
                }
            }

            parent = _recommendInf.GetIntroducer(parent);

            if ( plv >= _subProfits.length - 1 || parent == address(0x0) ) {
                break;
            }

            plv = _ownerLevelsMapping[parent];
        }

        uint256 L = _ownerLevelsMapping[nearestAddr];

        if ( nearestAddr != address(0x0) && L > 1 && nearestProfit > 0 ) {

            parent = nearestAddr;

            uint256 indexOffset = _subProfits.length;

            for (uint j = 0; j < _equalLvSearchDepth; j++) {

                parent = _recommendInf.GetIntroducer(parent);
                plv = _ownerLevelsMapping[parent];

                if ( plv <= L && plv > 1 ) {

                    addrs[indexOffset] = parent;
                    profits[indexOffset] = (nearestProfit * _equalLvProp) / 100;

                    if ( indexOffset + 1 >= len ) {
                        break;
                    }

                    indexOffset++;
                }
            }

        }

        return (len, addrs, profits);
    }

    function SetLevelSearchDepth( uint256 d ) external OwnerOnly {
        _searchLvLayerDepth = d;
    }

    function SetSearchRecommendDepth( uint256 d ) external OwnerOnly {
        _searchReommendDepth = d;
    }


    function SetEqualLvRule( uint256 p, uint256 limit, uint256 depth ) external OwnerOnly {
        _equalLvProp = p;
        _equalLvMaxLimit = limit;
        _equalLvSearchDepth = depth;
    }


    function SetLevelSubValues( uint256 lv, uint256 value ) external OwnerOnly {
        _subProfits[lv] = value;
    }
}
