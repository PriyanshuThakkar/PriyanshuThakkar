// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The balance of the smart contract is the total amount of money the bank has...
out of the total balance, amounts are linked to some or other account.
*/

/*
The initial amount of ether that each account has in it's address is considered to
be in form of cash which each account holder has initially.
*/

/* EMI Plans
 5 years - 12%
10 years - 8%
15 years - 5%
*/

contract Banking {
    struct account {
        bool validity;
        string name;
        uint256 balance;
        uint256 Mpin;
        uint256 interestAmount; //interest being recieved from the bank for keeping money.
        uint256 account_openning_time;
        uint256 account_time;
        bool EmiTaken;
        uint256 EMI;
        uint256 totalEMI;
        uint256 emiPaid;
        uint256 emiTime;
    }
    mapping(address => account) internal AccountDetails;
    address public Owner;

    constructor() {
        Owner = msg.sender;
    }

    // modifier OnlyOwner{
    //     require(msg.sender == Owner,"Owner access only.");
    //     _;
    // }

    function createMpin(uint256 _mpin) 
    internal 
    {
        AccountDetails[msg.sender].Mpin = _mpin;
    }

    function OpenAccount(address _accountAddress,string memory _name,uint256 _mpin) 
    external 
    {
        require(
            msg.sender == _accountAddress,
            "Cannot open account for others."
        );
        require(
            AccountDetails[_accountAddress].validity == false,
            "Account already Exists."
        );
        AccountDetails[_accountAddress].account_openning_time = block.timestamp;
        AccountDetails[_accountAddress].account_time = block.timestamp;
        AccountDetails[_accountAddress].validity = true;
        AccountDetails[_accountAddress].name = _name;
        createMpin(_mpin);
    }

    function CalculateDays(uint256 _endTime, uint256 _startTime)
        internal
        pure
        returns (uint256)
    {
        return ((_endTime - _startTime) / 86400);
    }

    function interest(uint256 _day) 
    internal 
    view 
    returns (uint256) 
    {
        return (((AccountDetails[msg.sender].balance * _day) * 4) / 36500); //rate is 4 percent
    }

    function fectch_Interest(uint _mpin)
    external
    view
    returns (uint256)
    {
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(
            AccountDetails[msg.sender].Mpin == _mpin, 
            "MPIN mismatch."
        );
        return(AccountDetails[msg.sender].interestAmount); 
    }
    
    function depositAmount(uint256 _mpin) 
    external 
    payable 
    {
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(
            AccountDetails[msg.sender].Mpin == _mpin, 
            "MPIN mismatch."
        );
        uint256 _time = block.timestamp;
        uint256 day = CalculateDays(
            _time,
            AccountDetails[msg.sender].account_time
        );
        AccountDetails[msg.sender].interestAmount = interest(day);
        AccountDetails[msg.sender].account_time = block.timestamp;
        AccountDetails[msg.sender].balance += msg.value;
    }

    function getBalance() 
    external 
    view 
    returns (uint256) 
    {
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        return AccountDetails[msg.sender].balance;
    }

    function withdraw(uint256 _mpin, uint256 _amount) 
    external 
    {
        //we get cash
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(AccountDetails[msg.sender].Mpin == _mpin, 
        "MPIN mismatch."
        );
        require(
            AccountDetails[msg.sender].balance >= _amount,
            "Insufficient funds."
        );
        uint256 _time = block.timestamp;
        uint256 day = CalculateDays(
            _time,
            AccountDetails[msg.sender].account_time
        );
        AccountDetails[msg.sender].interestAmount = interest(day);
        AccountDetails[msg.sender].account_time = block.timestamp;
        payable(msg.sender).transfer(_amount);
        AccountDetails[msg.sender].balance -= _amount;
    }

    function DepositInterestToAccount(uint256 _mpin) 
    external 
    {
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(
            AccountDetails[msg.sender].Mpin == _mpin, 
            "MPIN mismatch."
        );
        require(
            AccountDetails[msg.sender].interestAmount > 0,
            "No Interest recieved."
        );
        AccountDetails[msg.sender].balance += AccountDetails[msg.sender]
            .interestAmount;
        AccountDetails[msg.sender].interestAmount = 0;
        AccountDetails[msg.sender].account_time = block.timestamp;
    }

    function Calculate_EMI(uint256 _tenure, uint256 _amount)
    internal
    pure
    returns (uint256)
    {
        if (_tenure == 5) {
            return (((_amount + (_amount * 15 * 5) / 100) / 12) * 5);
        } else if (_tenure == 10) {
            return (((_amount + (_amount * 8 * 10) / 100) / 12) * 10);
        } else {
            return (((_amount + (_amount * 5 * 15) / 100) / 12) * 15);
        }
    }

    function TakeLoan(
    uint256 _mpin,
    uint256 _amount,
     uint256 tenure
    ) external {
        // we get amount deposited into our account and not in form of cash.
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(
            AccountDetails[msg.sender].Mpin == _mpin, 
            "MPIN mismatch."
        );
        require(
            tenure == 5 || tenure == 10 || tenure == 15,
            "Tenure can be 5, 10 or 15 years."
        );
        require(
            address(this).balance - AccountDetails[msg.sender].balance >
                _amount,
            "Bank has insufficient balance."
        );
        //the above function checks if the money bank has is more tha enough for the loan to pass.
        AccountDetails[msg.sender].balance += _amount;
        AccountDetails[msg.sender].EmiTaken = true;
        AccountDetails[msg.sender].EMI = Calculate_EMI(tenure, _amount);
        AccountDetails[msg.sender].totalEMI =
            AccountDetails[msg.sender].EMI *
            (tenure) *
            12;
        AccountDetails[msg.sender].emiTime = block.timestamp;
    }

    function PayEmi(uint256 _mpin) 
    external 
    {
        require(
            AccountDetails[msg.sender].validity, 
            "Account doesn't exist."
        );
        require(
            AccountDetails[msg.sender].Mpin == _mpin, 
            "MPIN mismatch."
        );
        require(
            AccountDetails[msg.sender].EmiTaken, 
            "No EMI for the account."
        );
        require(
            block.timestamp >= AccountDetails[msg.sender].emiTime + 2592000,
            "Can only Pay after a month."
        );
        // 2592000 represents 30 days
        require(
            AccountDetails[msg.sender].balance >=
                AccountDetails[msg.sender].EMI,
            "Insufficient funds."
        );
        AccountDetails[msg.sender].balance -= AccountDetails[msg.sender].EMI;
        AccountDetails[msg.sender].emiPaid += AccountDetails[msg.sender].EMI;
        AccountDetails[msg.sender].emiTime = block.timestamp;
        if (AccountDetails[msg.sender].emiPaid ==AccountDetails[msg.sender].totalEMI) {
            AccountDetails[msg.sender].EmiTaken = false;
        }
    }
}
