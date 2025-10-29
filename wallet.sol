// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UserWallet {
    address public immutable owner;
    string public walletName;
    
    struct TxRecord {
        address from;
        address to;
        uint96 amount;
        uint32 timestamp;
        string note;
    }

    TxRecord[] public transactions;

    event Deposit(address indexed from, uint256 amount, uint32 timestamp);
    event Sent(address indexed to, uint256 amount, uint32 timestamp);

    error Unauthorized();
    error TransferFailed();
    error ZeroAmount();
    error OutOfBounds();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _owner, string memory _walletName) payable {
        owner = _owner;
        walletName = _walletName;
        
        if (msg.value > 0) {
            transactions.push(TxRecord({
                from: msg.sender,
                to: address(this),
                amount: uint96(msg.value),
                timestamp: uint32(block.timestamp),
                note: "init"
            }));
            emit Deposit(msg.sender, msg.value, uint32(block.timestamp));
        }
    }

    receive() external payable {
        _recordDeposit(msg.sender, msg.value, "deposit");
    }

    function send(address payable _to, uint256 _amount, string calldata _note) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();
        if (_amount > address(this).balance) revert ZeroAmount();
        
        (bool ok, ) = _to.call{value: _amount}("");
        if (!ok) revert TransferFailed();

        transactions.push(TxRecord({
            from: address(this),
            to: _to,
            amount: uint96(_amount),
            timestamp: uint32(block.timestamp),
            note: _note
        }));
        emit Sent(_to, _amount, uint32(block.timestamp));
    }

    function withdrawAll(address payable _to) external onlyOwner {
        uint256 bal = address(this).balance;
        if (bal == 0) revert ZeroAmount();
        
        (bool ok, ) = _to.call{value: bal}("");
        if (!ok) revert TransferFailed();

        transactions.push(TxRecord({
            from: address(this),
            to: _to,
            amount: uint96(bal),
            timestamp: uint32(block.timestamp),
            note: "withdraw"
        }));
        emit Sent(_to, bal, uint32(block.timestamp));
    }

    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        _recordDeposit(msg.sender, msg.value, "manual");
    }

    function batchSend(address payable[] calldata _recipients, uint256[] calldata _amounts, string calldata _note) external onlyOwner {
        uint256 len = _recipients.length;
        require(len == _amounts.length && len > 0, "invalid input");
        
        for (uint256 i = 0; i < len;) {
            if (_amounts[i] > 0) {
                (bool ok, ) = _recipients[i].call{value: _amounts[i]}("");
                if (!ok) revert TransferFailed();
                
                transactions.push(TxRecord({
                    from: address(this),
                    to: _recipients[i],
                    amount: uint96(_amounts[i]),
                    timestamp: uint32(block.timestamp),
                    note: _note
                }));
                emit Sent(_recipients[i], _amounts[i], uint32(block.timestamp));
            }
            unchecked { ++i; }
        }
    }

    function getTransactions(uint256 _offset, uint256 _limit) external view returns (TxRecord[] memory) {
        uint256 total = transactions.length;
        if (_offset >= total) return new TxRecord[](0);
        
        uint256 end = _offset + _limit > total ? total : _offset + _limit;
        uint256 size = end - _offset;
        TxRecord[] memory result = new TxRecord[](size);
        
        for (uint256 i = 0; i < size;) {
            result[i] = transactions[_offset + i];
            unchecked { ++i; }
        }
        return result;
    }

    function transactionsCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 idx) external view returns (TxRecord memory) {
        if (idx >= transactions.length) revert OutOfBounds();
        return transactions[idx];
    }

    function _recordDeposit(address _from, uint256 _amount, string memory _note) private {
        transactions.push(TxRecord({
            from: _from,
            to: address(this),
            amount: uint96(_amount),
            timestamp: uint32(block.timestamp),
            note: _note
        }));
        emit Deposit(_from, _amount, uint32(block.timestamp));
    }
}

contract WalletManager {
    event UserRegistered(address indexed userEOA, address indexed walletContract);

    mapping(address => address) public userToWallet;
    mapping(address => bool) private isWallet;
    address[] public allWallets;

    error AlreadyRegistered();
    error InvalidWallet();

    function register(string calldata _walletName) external payable returns (address) {
        if (userToWallet[msg.sender] != address(0)) revert AlreadyRegistered();

        UserWallet w = (new UserWallet){value: msg.value}(msg.sender, _walletName);
        address walletAddr = address(w);

        userToWallet[msg.sender] = walletAddr;
        isWallet[walletAddr] = true;
        allWallets.push(walletAddr);

        emit UserRegistered(msg.sender, walletAddr);
        return walletAddr;
    }

    function getWallet(address _user) external view returns (address) {
        return userToWallet[_user];
    }

    function getAllWallets(uint256 _offset, uint256 _limit) external view returns (address[] memory) {
        uint256 total = allWallets.length;
        if (_offset >= total) return new address[](0);
        
        uint256 end = _offset + _limit > total ? total : _offset + _limit;
        uint256 size = end - _offset;
        address[] memory result = new address[](size);
        
        for (uint256 i = 0; i < size;) {
            result[i] = allWallets[_offset + i];
            unchecked { ++i; }
        }
        return result;
    }

    function walletsCount() external view returns (uint256) {
        return allWallets.length;
    }

    function verifyWallet(address _wallet) external view returns (bool) {
        return isWallet[_wallet];
    }
}