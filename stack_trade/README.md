# StackTrade: Digital Asset Exchange on Stacks

StackTrade is a decentralized marketplace built on the Stacks blockchain that enables peer-to-peer trading of digital content and assets.

## Overview

StackTrade provides a trustless platform where creators can monetize their digital content and consumers can purchase access to these assets using STX tokens. The smart contract handles secure transactions, access management, and creator royalties in a decentralized manner.

## Features

- **Content Marketplace**: List and discover digital assets of various types
- **Secure Access Management**: Purchased content is accessible only to authorized buyers
- **Fair Fee Structure**: Transparent fee mechanism with configurable rates
- **Owner Controls**: Content creators maintain control over pricing and availability
- **Transaction Records**: Complete history of marketplace activities
- **Trader Metrics**: Build reputation through successful transactions

## Smart Contract Methods

### For Content Creators

- `register-content`: List new digital content on the marketplace
- `modify-price`: Update the price of your listed content
- `delist-content`: Remove your content from being available for purchase

### For Buyers

- `acquire-content`: Purchase access to digital content
- `retrieve-access-token`: Get access credentials for purchased content

### Read-Only Functions

- `get-content-info`: View details about listed content
- `get-trader-info`: Check reputation metrics for marketplace participants
- `get-exchange-stats`: Get statistics about marketplace volume
- `get-current-fee`: See the current platform fee percentage

## Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): Local Stacks blockchain environment
- [Stacks.js](https://github.com/blockstack/stacks.js): JavaScript library for interacting with Stacks blockchain

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/kingdavid/stacktrade.git
   cd stacktrade
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Test the smart contract:
   ```bash
   clarinet check
   clarinet test
   ```

4. Deploy to testnet:
   ```bash
   # Update Clarinet.toml with your testnet configuration
   clarinet deploy --testnet
   ```

## Contract Structure

- **Storage Maps**:
  - `content-offerings`: Details about listed content
  - `trader-metrics`: Reputation data for marketplace participants
  - `exchange-records`: Transaction history
  - `content-keys`: Secure access credentials

- **Data Variables**:
  - `item-counter`: Unique ID assignment for content
  - `exchange-fee`: Current platform fee percentage
  - `exchange-volume`: Total transactions processed

## Usage Examples

### List New Content
```clarity
(contract-call? .stacktrade register-content u100000000 "Comprehensive Guide to Stacks Development" "educational/pdf" "https://example.com/access/t0ken123")
```

### Purchase Content
```clarity
(contract-call? .stacktrade acquire-content u1)
```

### Access Purchased Content
```clarity
(contract-call? .stacktrade retrieve-access-token u1)
```

## Production Deployment Notes

When deploying to the Stacks mainnet, ensure you update the `get-current-block-height` function to use the appropriate block height mechanism for your Clarity version:

```clarity
;; For newer Clarity versions with direct block-height support
(define-private (get-current-block-height)
    block-height
)

;; OR for versions with get-block-info? support
(define-private (get-current-block-height)
    (default-to u0 (get-block-info? height u0))
)
```

## Fee Structure

The platform charges a configurable percentage fee on each transaction (default: 3%). Fees are automatically calculated and distributed to the contract owner address during transactions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request