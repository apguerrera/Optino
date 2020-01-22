pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Vanilla Optino 📈 + Factory v0.90-pre-release
//
// A factory to conveniently deploy your own source code verified vanilla
// european optinos
//
// Factory deployment address: 0x{something}
//
// https://github.com/bokkypoobah/Optino
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract, with token recovery
// ----------------------------------------------------------------------------
contract Owned {
    bool initialised;
    address payable public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function init(address _owner) internal {
        require(!initialised);
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = address(uint160(newOwner));
        newOwner = address(0);
    }
    function recoverTokens(address token, uint tokens) public onlyOwner {
        if (token == address(0)) {
            owner.transfer((tokens == 0 ? address(this).balance : tokens));
        } else {
            ERC20Interface(token).transfer(owner, tokens == 0 ? ERC20Interface(token).balanceOf(address(this)) : tokens);
        }
    }
}


// ----------------------------------------------------------------------------
// ApproveAndCall Fallback
// NOTE for contracts implementing this interface:
// 1. An error must be thrown if there are errors executing `transferFrom(...)`
// 2. The calling token contract must be checked to prevent malicious behaviour
// ----------------------------------------------------------------------------
interface ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


// ----------------------------------------------------------------------------
// Token Interface = symbol + name + decimals + approveAndCall + mint + burn
// Use with ERC20Interface
// ----------------------------------------------------------------------------
interface TokenInterface {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(address tokenOwner, uint tokens) external returns (bool success);
}


contract Token is TokenInterface, ERC20Interface, Owned {
    using SafeMath for uint;

    string _symbol;
    string  _name;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function initToken(address tokenOwner, string memory symbol, string memory name, uint8 decimals, uint initialSupply) internal {
        super.init(tokenOwner);
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = initialSupply;
        balances[tokenOwner] = _totalSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }
    function symbol() override external view returns (string memory) {
        return _symbol;
    }
    function name() override external view returns (string memory) {
        return _name;
    }
    function decimals() override external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() override external view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // NOTE Only use this call with a trusted spender contract
    function approveAndCall(address spender, uint tokens, bytes calldata data) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function mint(address tokenOwner, uint tokens) override external onlyOwner returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(address tokenOwner, uint tokens) override external onlyOwner returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
    receive() external payable {
    }
    // function () external payable {
    //    revert();
    // }
}


// ----------------------------------------------------------------------------
// Vanilla Optino Formula
//
// Call optino - 10 units with strike 200, using spot of [150, 200, 250], collateral of 10 ETH
// - 10 OptinoToken created
//   - payoffInQuoteTokenPerUnitBaseToken = max(0, spot-strike) = [0, 0, 50] DAI
//   - payoffInQuoteToken = 10 * [0, 0, 500] DAI
//   * payoffInBaseTokenPerUnitBaseToken = payoffInQuoteTokenPerUnitBaseToken / [150, 200, 250] = [0, 0, 50/250] = [0, 0, 0.2] ETH
//   * payoffInBaseToken = payoffInBaseTokenPerUnitBaseToken * 10 = [0 * 10, 0 * 10, 0.2 * 10] = [0, 0, 2] ETH
// - 10 OptinoCollateralToken created
//   - payoffInQuoteTokenPerUnitBaseToken = spot - max(0, spot-strike) = [150, 200, 200] DAI
//   - payoffInQuoteToken = 10 * [1500, 2000, 2000] DAI
//   * payoffInBaseTokenPerUnitBaseToken = payoffInQuoteTokenPerUnitBaseToken / [150, 200, 250] = [1, 1, 200/250] = [1, 1, 0.8] ETH
//   * payoffInBaseToken = payoffInBaseTokenPerUnitBaseToken * 10 = [1 * 10, 1 * 10, 0.8 * 10] = [10, 10, 8] ETH
//
// Put optino - 10 units with strike 200, using spot of [150, 200, 250], collateral of 2000 DAI
// - 10 OptinoToken created
//   * payoffInQuoteTokenPerUnitBaseToken = max(0, strike-spot) = [50, 0, 0] DAI
//   * payoffInQuoteToken = 10 * [500, 0, 0] DAI
//   - payoffInBaseTokenPerUnitBaseToken = payoffInQuoteTokenPerUnitBaseToken / [150, 200, 250] = [50/150, 0/200, 0/250] = [0.333333333, 0, 0] ETH
//   - payoffInBaseToken = payoffInBaseTokenPerUnitBaseToken * 10 = [0.333333333 * 10, 0 * 10, 0 * 10] = [3.333333333, 0, 0] ETH
// - 10 OptinoCollateralToken created
//   * payoffInQuoteTokenPerUnitBaseToken = strike - max(0, strike-spot) = [150, 200, 200] DAI
//   * payoffInQuoteToken = 10 * [1500, 2000, 2000] DAI
//   - payoffInBaseTokenPerUnitBaseToken = payoffInQuoteTokenPerUnitBaseToken / spot
//   - payoffInBaseTokenPerUnitBaseToken = [150, 200, 200] / [150, 200, 250] = [1, 1, 200/250] = [1, 1, 0.8] ETH
//   - payoffInBaseToken = payoffInBaseTokenPerUnitBaseToken * 10 = [1 * 10, 1 * 10, 0.8 * 10] = [10, 10, 8] ETH
//
//
// ----------------------------------------------------------------------------
library VanillaOptinoFormulae {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Payoff for baseToken/quoteToken, e.g. ETH/DAI
    //   OptionToken:
    //     Call
    //       payoffInQuoteToken = max(0, spot - strike)
    //       payoffInBaseToken = payoffInQuoteToken / (spot / 10^rateDecimals)
    //     Put
    //       payoffInQuoteToken = max(0, strike - spot)
    //       payoffInBaseToken = payoffInQuoteToken / (spot / 10^rateDecimals)
    //   OptionCollateralToken:
    //     Call
    //       payoffInQuoteToken = spot - max(0, spot - strike)
    //       payoffInBaseToken = payoffInQuoteToken / (spot / 10^rateDecimals)
    //     Put
    //       payoffInQuoteToken = strike - max(0, strike - spot)
    //       payoffInBaseToken = payoffInQuoteToken / (spot / 10^rateDecimals)
    //
    // NOTE: strike and spot at rateDecimals decimal places, 18 in this contract
    // ------------------------------------------------------------------------
    function payoff(uint _callPut, uint _strike, uint _spot, uint _baseTokens, uint _baseDecimals) internal pure returns (uint _payoffInBaseToken, uint _payoffInQuoteToken, uint _collateralPayoffInBaseToken, uint _collateralPayoffInQuoteToken) {
        if (_callPut == 0) {
            if (_spot <= _strike) {
                _payoffInQuoteToken = 0;
            } else {
                _payoffInQuoteToken = _spot.sub(_strike);
            }
            _collateralPayoffInQuoteToken = _spot.sub(_payoffInQuoteToken);
        } else {
            if (_spot >= _strike) {
                _payoffInQuoteToken = 0;
            } else {
                _payoffInQuoteToken = _strike.sub(_spot);
            }
            _collateralPayoffInQuoteToken = _strike.sub(_payoffInQuoteToken);
        }
        _payoffInBaseToken = _payoffInQuoteToken * 10 ** 18 / _spot;
        _collateralPayoffInBaseToken = _collateralPayoffInQuoteToken * 10 ** 18 / _spot;

        _payoffInBaseToken = _payoffInBaseToken * _baseTokens / 10 ** _baseDecimals;
        _payoffInQuoteToken = _payoffInQuoteToken * _baseTokens / 10 ** _baseDecimals;
        _collateralPayoffInBaseToken = _collateralPayoffInBaseToken * _baseTokens / 10 ** _baseDecimals;
        _collateralPayoffInQuoteToken = _collateralPayoffInQuoteToken * _baseTokens / 10 ** _baseDecimals;
    }
}


// ----------------------------------------------------------------------------
// OptinoToken 📈 = Token + payoff
// ----------------------------------------------------------------------------
contract OptinoToken is Token {
    bool public isCollateral;
    address public pair;

    function initOptinoToken(address tokenOwner, string memory symbol, string memory name, uint8 decimals, uint initialSupply, bool _isCollateral) public {
        super.initToken(tokenOwner, symbol, name, decimals, initialSupply);
        isCollateral = _isCollateral;
    }
    function setPair(address _pair) public onlyOwner {
        pair = _pair;
    }
}


// ----------------------------------------------------------------------------
// Config - [baseToken, quoteToken, priceFeed] => [maxTerm, fee, description]
// ----------------------------------------------------------------------------
library ConfigLibrary {
    struct Config {
        uint timestamp;
        uint index;
        bytes32 key;
        address baseToken;
        address quoteToken;
        address priceFeed;
        uint maxTerm;
        uint fee;
        string description;
    }
    struct Data {
        bool initialised;
        mapping(bytes32 => Config) entries;
        bytes32[] index;
    }

    event ConfigAdded(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint maxTerm, uint fee, string description);
    event ConfigRemoved(address indexed baseToken, address indexed quoteToken, address indexed priceFeed);
    event ConfigUpdated(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint maxTerm, uint fee, string description);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function generateKey(address baseToken, address quoteToken, address priceFeed) internal pure returns (bytes32 hash) {
        return keccak256(abi.encodePacked(baseToken, quoteToken, priceFeed));
    }
    function hasKey(Data storage self, bytes32 key) internal view returns (bool) {
        return self.entries[key].timestamp > 0;
    }
    function add(Data storage self, address baseToken, address quoteToken, address priceFeed, uint maxTerm, uint fee, string memory description) internal {
        require(baseToken != quoteToken, "Config.add: baseToken cannot be the same as quoteToken");
        require(priceFeed != address(0), "Config.add: priceFeed cannot be null");
        require(maxTerm > 0, "Config.add: maxTerm must be > 0");
        bytes32 key = generateKey(baseToken, quoteToken, priceFeed);
        require(self.entries[key].timestamp == 0, "Config.add: Cannot add duplicate");
        self.index.push(key);
        self.entries[key] = Config(block.timestamp, self.index.length - 1, key, baseToken, quoteToken, priceFeed, maxTerm, fee, description);
        emit ConfigAdded(baseToken, quoteToken, priceFeed, maxTerm, fee, description);
    }
    function remove(Data storage self, address baseToken, address quoteToken, address priceFeed) internal {
        bytes32 key = generateKey(baseToken, quoteToken, priceFeed);
        require(self.entries[key].timestamp > 0);
        uint removeIndex = self.entries[key].index;
        emit ConfigRemoved(baseToken, quoteToken, priceFeed);
        uint lastIndex = self.index.length - 1;
        bytes32 lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[key];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function update(Data storage self, address baseToken, address quoteToken, address priceFeed, uint maxTerm, uint fee, string memory description) internal {
        bytes32 key = generateKey(baseToken, quoteToken, priceFeed);
        Config storage _value = self.entries[key];
        require(_value.timestamp > 0);
        _value.timestamp = block.timestamp;
        _value.maxTerm = maxTerm;
        _value.fee = fee;
        _value.description = description;
        emit ConfigUpdated(baseToken, quoteToken, priceFeed, maxTerm, fee, description);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}



// ----------------------------------------------------------------------------
// Series - [baseToken, quoteToken, priceFeed, callPut, expiry, strike] =>
// [description, optinoToken, optinoCollateralToken]
// ----------------------------------------------------------------------------
library SeriesLibrary {
    struct Series {
        uint timestamp;
        uint index;
        bytes32 key;
        address baseToken;
        address quoteToken;
        address priceFeed;
        uint callPut;
        uint expiry;
        uint strike;
        string description;
        address optinoToken;
        address optinoCollateralToken;
    }
    struct Data {
        bool initialised;
        mapping(bytes32 => Series) entries;
        bytes32[] index;
    }

    // Config copy of events to be generated in the ABI
    event ConfigAdded(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint maxTerm, uint fee, string description);
    event ConfigRemoved(address indexed baseToken, address indexed quoteToken, address indexed priceFeed);
    event ConfigUpdated(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint maxTerm, uint fee, string description);
    // SeriesLibrary copy of events to be generated in the ABI
    event SeriesAdded(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike, string description, address optinoToken, address optinoCollateralToken);
    event SeriesRemoved(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike);
    event SeriesUpdated(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike, string description);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function generateKey(address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike) internal pure returns (bytes32 hash) {
        return keccak256(abi.encodePacked(baseToken, quoteToken, priceFeed, callPut, expiry, strike));
    }
    function hasKey(Data storage self, bytes32 key) internal view returns (bool) {
        return self.entries[key].timestamp > 0;
    }
    function add(Data storage self, address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike, string memory description, address optinoToken, address optinoCollateralToken) internal {
        require(baseToken != quoteToken, "SeriesLibrary.add: baseToken cannot be the same as quoteToken");
        require(priceFeed != address(0), "SeriesLibrary.add: priceFeed cannot be null");
        require(callPut < 2, "SeriesLibrary.add: callPut must be 0 (call) or 1 (callPut)");
        require(expiry > block.timestamp, "SeriesLibrary.add: expiry must be in the future");
        require(strike > 0, "SeriesLibrary.add: strike must be non-zero");
        require(optinoToken != address(0), "SeriesLibrary.add: optinoToken cannot be null");
        require(optinoCollateralToken != address(0), "SeriesLibrary.add: optinoCollateralToken cannot be null");

        bytes32 key = generateKey(baseToken, quoteToken, priceFeed, callPut, expiry, strike);
        require(self.entries[key].timestamp == 0, "Series.add: Cannot add duplicate");
        self.index.push(key);
        self.entries[key] = Series(block.timestamp, self.index.length - 1, key, baseToken, quoteToken, priceFeed, callPut, expiry, strike, description, optinoToken, optinoCollateralToken);
        emit SeriesAdded(baseToken, quoteToken, priceFeed, callPut, expiry, strike, description, optinoToken, optinoCollateralToken);
    }
    function remove(Data storage self, address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike) internal {
        bytes32 key = generateKey(baseToken, quoteToken, priceFeed, callPut, expiry, strike);
        require(self.entries[key].timestamp > 0);
        uint removeIndex = self.entries[key].index;
        emit SeriesRemoved(baseToken, quoteToken, priceFeed, callPut, expiry, strike);
        uint lastIndex = self.index.length - 1;
        bytes32 lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[key];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function update(Data storage self, address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike, string memory description) internal {
        bytes32 key = generateKey(baseToken, quoteToken, priceFeed, callPut, expiry, strike);
        Series storage _value = self.entries[key];
        require(_value.timestamp > 0);
        _value.timestamp = block.timestamp;
        _value.description = description;
        emit SeriesUpdated(baseToken, quoteToken, priceFeed, callPut, expiry, strike, description);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}



// ----------------------------------------------------------------------------
// BokkyPooBah's Vanilla Optino 📈 Factory
//
// Note: If `newAddress` is not null, it will point to the upgraded contract
// ----------------------------------------------------------------------------
contract BokkyPooBahsVanillaOptinoFactory is Owned {
    using SafeMath for uint;
    using ConfigLibrary for ConfigLibrary.Data;
    using ConfigLibrary for ConfigLibrary.Config;
    using SeriesLibrary for SeriesLibrary.Data;
    using SeriesLibrary for SeriesLibrary.Series;

    struct OptinoData {
        address account;
        address baseToken;
        address quoteToken;
        address priceFeed;
        uint callPut;
        uint expiry;
        uint strike;
        uint baseTokens;
    }

    address public constant ETH = 0x0000000000000000000000000000000000000000;
    uint public constant RATEDECIMALS = 18;
    uint public constant OPTIONDECIMALS = 18;

    address public newAddress;

    ConfigLibrary.Data private configData;
    SeriesLibrary.Data private seriesData;

    // uint public minimumFee = 0.1 ether;
    // mapping(address => bool) public isChild;
    // address[] public children;

    event SeriesAdded(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike, string description, address optinoToken, address optinoCollateralToken);
    event SeriesRemoved(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike);
    event SeriesUpdated(address indexed baseToken, address indexed quoteToken, address indexed priceFeed, uint callPut, uint expiry, uint strike, string description);

    event FactoryDeprecated(address _newAddress);
    // event MinimumFeeUpdated(uint oldFee, uint newFee);
    // event TokenDeployed(address indexed owner, address indexed token, string symbol, string name, uint8 decimals, uint totalSupply, address uiFeeAccount, uint ownerFee, uint uiFee);

    constructor () public {
        super.init(msg.sender);
    }
    function deprecateFactory(address _newAddress) public onlyOwner {
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }

    // ----------------------------------------------------------------------------
    // Config
    // ----------------------------------------------------------------------------
    function addConfig(address baseToken, address quoteToken, address priceFeed, uint maxTerm, uint takerFee, string memory description) public onlyOwner {
        if (!configData.initialised) {
            configData.init();
        }
        configData.add(baseToken, quoteToken, priceFeed, maxTerm, takerFee, description);
    }
    function updateConfig(address baseToken, address quoteToken, address priceFeed, uint maxTerm, uint takerFee, string memory description) public onlyOwner {
        require(configData.initialised);
        configData.update(baseToken, quoteToken, priceFeed, maxTerm, takerFee, description);
    }
    function removeConfig(address baseToken, address quoteToken, address priceFeed) public onlyOwner {
        require(configData.initialised);
        configData.remove(baseToken, quoteToken, priceFeed);
    }
    function configDataLength() public view returns (uint) {
        return configData.length();
    }
    function getConfigByIndex(uint i) public view returns (bytes32, address, address, address, uint, uint, string memory, uint) {
        require(i < configData.length(), "getConfigByIndex: Invalid config index");
        ConfigLibrary.Config memory config = configData.entries[configData.index[i]];
        return (config.key, config.baseToken, config.quoteToken, config.priceFeed, config.maxTerm, config.fee, config.description, config.timestamp);
    }
    function _getConfig(OptinoData memory optinoData) internal view returns (ConfigLibrary.Config memory) {
        bytes32 key = ConfigLibrary.generateKey(optinoData.baseToken, optinoData.quoteToken, optinoData.priceFeed);
        return configData.entries[key];
    }


    // ----------------------------------------------------------------------------
    // Series
    // ----------------------------------------------------------------------------
    function addSeries(OptinoData memory optinoData, string memory description, address optinoToken, address optinoCollateralToken) internal {
        if (!seriesData.initialised) {
            seriesData.init();
        }
        seriesData.add(optinoData.baseToken, optinoData.quoteToken, optinoData.priceFeed, optinoData.callPut, optinoData.expiry, optinoData.strike, description, optinoToken, optinoCollateralToken);
    }
    function updateSeries(address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike, string memory description) internal {
        require(seriesData.initialised);
        seriesData.update(baseToken, quoteToken, priceFeed, callPut, expiry, strike, description);
    }
    function seriesDataLength() public view returns (uint) {
        return seriesData.length();
    }
    function getSeriesByIndex(uint i) public view returns (bytes32, address, address, address, uint, uint, uint, string memory, uint, address, address) {
        require(i < configData.length(), "getSeriesByIndex: Invalid config index");
        SeriesLibrary.Series memory series = seriesData.entries[seriesData.index[i]];
        return (series.key, series.baseToken, series.quoteToken, series.priceFeed, series.callPut, series.expiry, series.strike, series.description, series.timestamp, series.optinoToken, series.optinoCollateralToken);
    }
    function _getSeries(OptinoData memory optinoData) internal view returns (SeriesLibrary.Series storage) {
        bytes32 key = SeriesLibrary.generateKey(optinoData.baseToken, optinoData.quoteToken, optinoData.priceFeed, optinoData.callPut, optinoData.expiry, optinoData.strike);
        return seriesData.entries[key];
    }


    // ----------------------------------------------------------------------------
    // Mint optino tokens
    // ----------------------------------------------------------------------------
    function mintOptinoTokens(address baseToken, address quoteToken, address priceFeed, uint callPut, uint expiry, uint strike, uint baseTokens) public payable {
        _mintOptinoTokens(OptinoData(msg.sender, baseToken, quoteToken, priceFeed, callPut, expiry, strike, baseTokens));
    }
    function _mintOptinoTokens(OptinoData memory optinoData) internal returns (address, address) {
        // Check parameters not checked in SeriesLibrary and ConfigLibrary
        require(optinoData.expiry > block.timestamp, "mintOptinoTokens: expiry must be in the future");
        require(optinoData.baseTokens > 0, "mintOptinoTokens: baseTokens must be non-zero");

        SeriesLibrary.Series storage series = _getSeries(optinoData);

        OptinoToken optinoToken;
        OptinoToken optinoCollateralToken;
        // Series has not been created yet
        if (series.timestamp == 0) {
            // Check config registered
            ConfigLibrary.Config memory config = _getConfig(optinoData);
            require(config.timestamp > 0, "mintOptinoTokens: Invalid config");
            require(optinoData.expiry < (block.timestamp + config.maxTerm), "trade: expiry > config.maxTerm");
            optinoToken = new OptinoToken();
            optinoToken.initOptinoToken(address(this), "Optino", "OptinoName", uint8(OPTIONDECIMALS), 0, false);
            optinoCollateralToken = new OptinoToken();
            optinoCollateralToken.initOptinoToken(address(this), "OptinoCollateral", "OptinoCollateralName", uint8(OPTIONDECIMALS), 0, true);
            optinoToken.setPair(address(optinoCollateralToken));
            optinoCollateralToken.setPair(address(optinoToken));
            addSeries(optinoData, config.description, address(optinoToken), address(optinoCollateralToken));
            series = _getSeries(optinoData);
        } else {
            optinoToken = OptinoToken(payable(series.optinoToken));
            optinoCollateralToken = OptinoToken(payable(series.optinoCollateralToken));
        }
        optinoToken.mint(msg.sender, optinoData.baseTokens);
        optinoCollateralToken.mint(msg.sender, optinoData.baseTokens);

        if (optinoData.callPut == 0) {
            if (optinoData.baseToken == ETH) {
                require(msg.value >= optinoData.baseTokens, "mintOptinoTokens: Insufficient ETH sent");
                payable(address(optinoCollateralToken)).transfer(optinoData.baseTokens);
                uint refund = msg.value - optinoData.baseTokens;
                if (refund > 0) {
                    msg.sender.transfer(refund);
                }
            } else {
                require(ERC20Interface(optinoData.baseToken).balanceOf(msg.sender) >= optinoData.baseTokens);
                require(ERC20Interface(optinoData.baseToken).allowance(msg.sender, address(this)) > optinoData.baseTokens);
                ERC20Interface(optinoData.baseToken).transferFrom(msg.sender, address(optinoCollateralToken), optinoData.baseTokens);
            }
        } else {
            uint quoteTokens = optinoData.baseTokens * optinoData.strike / 10 ** RATEDECIMALS;
            if (optinoData.quoteToken == ETH) {
                require(msg.value >= quoteTokens, "mintOptinoTokens: Insufficient ETH sent");
                payable(address(optinoCollateralToken)).transfer(quoteTokens);
                uint refund = msg.value - quoteTokens;
                if (refund > 0) {
                    msg.sender.transfer(refund);
                }
            } else {
                require(ERC20Interface(optinoData.quoteToken).balanceOf(msg.sender) >= quoteTokens);
                require(ERC20Interface(optinoData.quoteToken).allowance(msg.sender, address(this)) > quoteTokens);
                ERC20Interface(optinoData.quoteToken).transferFrom(msg.sender, address(optinoCollateralToken), quoteTokens);
            }
        }

        return (series.optinoToken, series.optinoCollateralToken);
    }


    function payoff(uint _callPut, uint _strike, uint _spot, uint _baseTokens, uint _baseDecimals) public pure returns (uint _payoffInBaseToken, uint _payoffInQuoteToken, uint _collateralPayoffInBaseToken, uint _collateralPayoffInQuoteToken) {
        return VanillaOptinoFormulae.payoff(_callPut, _strike, _spot, _baseTokens, _baseDecimals);
    }


    // function numberOfChildren() public view returns (uint) {
    //     return children.length;
    // }
    // function setMinimumFee(uint _minimumFee) public onlyOwner {
    //     emit MinimumFeeUpdated(minimumFee, _minimumFee);
    //     minimumFee = _minimumFee;
    // }
    // function deployTokenContract(
    //     string memory symbol,
    //     string memory name,
    //     uint8 decimals,
    //     uint totalSupply,
    //     address payable uiFeeAccount
    // ) public payable returns (
    //     Token token
    // ) {
    //     require(msg.value >= minimumFee);
    //     require(decimals <= 27);
    //     require(totalSupply > 0);
    //     token = new Token();
    //     token.init(msg.sender, symbol, name, decimals, totalSupply);
    //     isChild[address(token)] = true;
    //     children.push(address(token));
    //     uint uiFee;
    //     uint ownerFee;
    //     if (uiFeeAccount == address(0) || uiFeeAccount == owner) {
    //         uiFee = 0;
    //         ownerFee = msg.value;
    //     } else {
    //         uiFee = msg.value / 2;
    //         ownerFee = msg.value - uiFee;
    //     }
    //     if (uiFee > 0) {
    //         uiFeeAccount.transfer(uiFee);
    //     }
    //     if (ownerFee > 0) {
    //         owner.transfer(ownerFee);
    //     }
    //     emit TokenDeployed(owner, address(token), symbol, name, decimals, totalSupply, uiFeeAccount, ownerFee, uiFee);
    // }

    // function () external payable {
    //     revert();
    // }
}