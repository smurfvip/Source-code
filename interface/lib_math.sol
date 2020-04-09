pragma solidity >=0.5.0 <0.6.0;

library lib_math {

    function CurrentDayzeroTime() public view returns (uint256) {
        return (now / OneDay()) * OneDay();
    }

    function ConvertTimeToDay(uint256 t) public pure returns (uint256) {
        return (t / OneDay()) * OneDay();
    }

    function OneDay() public pure returns (uint256) {
        
        return 1 days;
    }

    function OneHours() public pure returns (uint256) {
        return 1 hours;
    }

}
