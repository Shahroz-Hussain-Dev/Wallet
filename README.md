A gas-optimized, feature-rich smart contract wallet system for managing native currency on EVM-compatible blockchains.

The system consists of two contracts:
- **UserWallet**: Individual smart contract wallets with transaction history tracking
- **WalletManager**: Factory contract for user registration and wallet deployment

## Features

### UserWallet
- ✅ Owned wallet with access control
- ✅ Transaction history with timestamps and notes
- ✅ Direct deposits via `receive()` function
- ✅ Batch sending to multiple recipients
- ✅ Paginated transaction retrieval
- ✅ Gas-optimized storage (packed structs)
- ✅ Custom error handling

### WalletManager
- ✅ One-click wallet deployment
- ✅ User-to-wallet mapping
- ✅ Wallet verification
- ✅ Paginated wallet listing
- ✅ Optional initial funding during registration

## Contract Architecture

### UserWallet

```solidity
struct TxRecord {
    address from;      // Sender address
    address to;        // Recipient address
    uint96 amount;     // Transfer amount (packed)
    uint32 timestamp;  // Block timestamp (packed)
    string note;       // Transaction note
}
```

**Key Functions:**

| Function | Access | Description |
|----------|--------|-------------|
| `send()` | Owner | Send funds to a recipient with a note |
| `withdrawAll()` | Owner | Withdraw entire balance |
| `batchSend()` | Owner | Send to multiple recipients in one tx |
| `deposit()` | Public | Manual deposit with validation |
| `getTransactions()` | Public | Retrieve paginated transaction history |
| `getTransaction()` | Public | Get single transaction by index |
| `transactionsCount()` | Public | Total transaction count |

### WalletManager

**Key Functions:**

| Function | Access | Description |
|----------|--------|-------------|
| `register()` | Public | Deploy a new UserWallet for caller |
| `getWallet()` | Public | Get wallet address for a user |
| `getAllWallets()` | Public | Retrieve paginated list of all wallets |
| `walletsCount()` | Public | Total registered wallets |
| `verifyWallet()` | Public | Check if address is a registered wallet |

## Usage Examples

### Deploy WalletManager

```solidity
WalletManager manager = new WalletManager();
```

### Register a New Wallet

```solidity
// Register without initial funding
address myWallet = manager.register("My Wallet");

// Register with initial funding (1 ETH)
address fundedWallet = manager.register{value: 1 ether}("Funded Wallet");
```

### Send Funds

```solidity
UserWallet wallet = UserWallet(payable(myWallet));

// Single send
wallet.send(payable(recipient), 0.5 ether, "Payment for services");

// Batch send
address payable[] memory recipients = new address payable[](3);
uint256[] memory amounts = new uint256[](3);
recipients[0] = payable(0x123...);
recipients[1] = payable(0x456...);
recipients[2] = payable(0x789...);
amounts[0] = 0.1 ether;
amounts[1] = 0.2 ether;
amounts[2] = 0.3 ether;
wallet.batchSend(recipients, amounts, "Batch payment");
```

### Deposit Funds

```solidity
// Direct deposit via receive()
(bool success, ) = address(wallet).call{value: 1 ether}("");

// Explicit deposit
wallet.deposit{value: 1 ether}();
```

### Query Transaction History

```solidity
// Get total count
uint256 total = wallet.transactionsCount();

// Get paginated transactions (offset: 0, limit: 10)
UserWallet.TxRecord[] memory txs = wallet.getTransactions(0, 10);

// Get specific transaction
UserWallet.TxRecord memory tx = wallet.getTransaction(5);
```

### List All Wallets

```solidity
// Get total wallets
uint256 totalWallets = manager.walletsCount();

// Get first 50 wallets
address[] memory wallets = manager.getAllWallets(0, 50);

// Verify a wallet
bool isValid = manager.verifyWallet(walletAddress);
```

## Gas Optimizations

1. **Immutable Owner**: Owner address stored as immutable, saving ~2100 gas per read
2. **Packed Structs**: `uint96` for amounts and `uint32` for timestamps reduce storage slots
3. **Custom Errors**: Replace `require` strings with custom errors (saves ~24 gas per revert)
4. **Unchecked Loops**: Safe arithmetic optimizations in iteration
5. **Batch Operations**: Send to multiple recipients in a single transaction

## Security Features

- **Access Control**: Only wallet owner can send funds
- **Transfer Validation**: All transfers checked for success
- **Registration Lock**: Users can only register once
- **Amount Validation**: Zero-amount transactions rejected
- **Bounds Checking**: Array access validated

## Events

### UserWallet Events
```solidity
event Deposit(address indexed from, uint256 amount, uint32 timestamp);
event Sent(address indexed to, uint256 amount, uint32 timestamp);
```

### WalletManager Events
```solidity
event UserRegistered(address indexed userEOA, address indexed walletContract);
```

## Custom Errors

```solidity
error Unauthorized();      // Caller is not the owner
error TransferFailed();    // Native currency transfer failed
error ZeroAmount();        // Amount is zero or insufficient
error OutOfBounds();       // Array index out of bounds
error AlreadyRegistered(); // User already has a wallet
error InvalidWallet();     // Address is not a registered wallet
```

## Requirements

- Solidity ^0.8.20
- EVM-compatible blockchain
- No external dependencies

## License

MIT

## Deployment Considerations

- WalletManager deployment cost: ~1.2M gas
- UserWallet deployment cost: ~650K gas per wallet
- Recommended gas price: Check current network conditions
- Initial funding: Optional during registration

## Integration Tips

1. **Frontend Integration**: Use event logs to track wallet creation and transactions
2. **Pagination**: Always use paginated functions for large datasets to avoid gas limits
3. **Error Handling**: Catch custom errors for better UX feedback
4. **Batch Operations**: Use `batchSend()` for multiple payments to save gas
5. **Transaction Notes**: Keep notes concise to minimize storage costs

## Testing Recommendations

- Test wallet deployment with and without initial funding
- Verify access control on all owner-only functions
- Test edge cases (zero amounts, empty arrays)
- Validate pagination boundaries
- Test batch sends with varying array sizes
- Verify event emissions

## Future Enhancements

Potential additions for future versions:
- ERC20 token support
- Multi-signature functionality
- Spending limits and allowances
- Transaction scheduling
- Wallet recovery mechanisms
- Gas abstraction/meta-transactions
