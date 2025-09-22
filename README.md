# RWA Core Contract

A comprehensive Real World Assets (RWA) tokenization framework built on Ethereum, featuring compliance, identity verification, and security token management.

## Overview

This project implements a complete RWA tokenization system with three core components:

- **SecurityToken**: ERC20-compliant security token with compliance integration
- **Compliance**: Configurable compliance engine supporting jurisdiction restrictions, lockup periods, and role-based access
- **IdentityRegistry**: KYC/AML identity management system with jurisdiction and role tracking

## Features

### 🔐 Security Token
- ERC20-compliant with OpenZeppelin v5
- Built-in compliance checks on every transfer
- Role-based access control (Admin, Transfer Agent)
- Mint/burn functionality for token lifecycle management

### 📋 Compliance Engine
- **Jurisdiction Whitelisting**: Control transfers based on sender/receiver jurisdictions
- **US Lockup Periods**: Enforce Reg D-style lockup periods for US investors
- **Role Requirements**: Require specific investor roles (e.g., Professional, Accredited)
- **Configurable Rules**: Easily extensible for additional compliance requirements

### 🆔 Identity Registry
- **KYC/AML Verification**: Track verification status and expiration dates
- **Jurisdiction Mapping**: Assign jurisdiction codes (840=USA, 276=Germany, etc.)
- **Role Management**: Support for investor classifications (Accredited, Professional, etc.)
- **Admin Controls**: Centralized identity management

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SecurityToken   │    │ Compliance      │    │ IdentityRegistry│
│                 │    │                 │    │                 │
│ • ERC20 Token   │◄──►│ • Transfer Rules│◄──►│ • KYC/AML Data  │
│ • Mint/Burn     │    │ • Jurisdictions │    │ • Jurisdictions │
│ • Role Control  │    │ • Lockup Periods│    │ • Investor Roles│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rwa-core-contract
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   Create a `.env` file in the project root:
   ```env
   SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
   HOLESKY_RPC_URL=https://ethereum-holesky.publicnode.com
   PRIVATE_KEY=your_wallet_private_key
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

## Deployment

### Compile Contracts

First, compile your contracts:

```bash
npx hardhat compile
```

### Deploy to Sepolia Testnet

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

The deployment script will:
1. Deploy `IdentityRegistry` with admin privileges
2. Deploy `Compliance` contract linked to the registry
3. Deploy `SecurityToken` ("GPI Fund", "GPI") with compliance integration
4. Configure basic jurisdiction rules (USA, Germany, France, China)

### Deploy to Holesky Testnet

```bash
npx hardhat run scripts/deploy.js --network holesky
```

## Deployed Contracts

### Sepolia Testnet Deployment

**Deployer Address:** `0xe117f73535C8032DEf628BDE35B767a1f93682Cb`

| Contract | Address |
|----------|---------|
| IdentityRegistry | `0x621E427e081Bf8F366e70213C9082b1817357e7f` |
| Compliance | `0xD881F04F0E0ff688AaAfc7b9e279D9d3ab886aB3` |
| SecurityToken | `0xf9BD8824bce013f29A340bc44f000Eb37DA7a5E3` |

> **Note:** SecurityToken deployment may fail if the previous contracts haven't been deployed yet. Make sure to deploy in the correct order as specified in the deployment script.

### Contract Verification

After deployment, verify your contracts on Etherscan:

```bash
# Verify IdentityRegistry
npx hardhat verify --network sepolia <IdentityRegistryAddress> "<deployer>"

# Verify Compliance
npx hardhat verify --network sepolia <ComplianceAddress> "<deployer>" "<IdentityRegistryAddress>"

# Verify SecurityToken
npx hardhat verify --network sepolia <SecurityTokenAddress> "Acme RWA Fund" "ARF" "<deployer>" "<ComplianceAddress>"
```

**Example with actual addresses:**
```bash
# Verify IdentityRegistry
npx hardhat verify --network sepolia 0x621E427e081Bf8F366e70213C9082b1817357e7f "0xe117f73535C8032DEf628BDE35B767a1f93682Cb"

# Verify Compliance
npx hardhat verify --network sepolia 0xD881F04F0E0ff688AaAfc7b9e279D9d3ab886aB3 "0xe117f73535C8032DEf628BDE35B767a1f93682Cb" "0x621E427e081Bf8F366e70213C9082b1817357e7f"

# Verify SecurityToken
npx hardhat verify --network sepolia 0xf9BD8824bce013f29A340bc44f000Eb37DA7a5E3 "GPI Fund" "GPI" "0xe117f73535C8032DEf628BDE35B767a1f93682Cb" "0xD881F04F0E0ff688AaAfc7b9e279D9d3ab886aB3"
```

## Usage Examples

### Setting Up Investor Identities

```javascript
// Set up a US accredited investor
await identityRegistry.setIdentity(
  investorAddress,
  true,                    // isVerified
  840,                     // jurisdiction (USA)
  "ACCREDITED",           // role
  Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60  // valid for 1 year
);
```

### Configuring Compliance Rules

```javascript
// Allow specific jurisdictions
await compliance.allowJurisdiction(840, true);  // USA
await compliance.allowJurisdiction(276, true);  // Germany

// Set US lockup period (12 months)
const lockupEnd = Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60;
await compliance.setUSLockup(investorAddress, lockupEnd);

// Require professional role for certain recipients
await compliance.setRequiredRoleForRecipient(
  professionalInvestorAddress,
  "PROFESSIONAL"
);
```

### Token Operations

```javascript
// Mint tokens to verified investors
await securityToken.mint(investorAddress, ethers.parseEther("1000"));

// Transfers automatically check compliance
await securityToken.transfer(recipientAddress, ethers.parseEther("100"));
```

## Compliance Rules

The compliance engine enforces the following rules:

1. **Identity Verification**: Both sender and recipient must be verified and not expired
2. **Jurisdiction Whitelist**: Both parties must be from allowed jurisdictions
3. **US Lockup Periods**: US investors may be subject to lockup periods
4. **Role Requirements**: Some recipients may require specific investor roles

## Jurisdiction Codes

Common jurisdiction codes used in the system:

| Code | Country/Region |
|------|----------------|
| 840  | United States  |
| 276  | Germany        |
| 250  | France         |
| 156  | China          |
| 724  | Spain          |
| 826  | United Kingdom |

## Testing

```bash
# Run tests
npx hardhat test

# Run tests with gas reporting
REPORT_GAS=true npx hardhat test
```

## Security Considerations

- **Private Keys**: Never commit private keys to version control
- **Admin Roles**: Carefully manage admin privileges
- **Compliance Updates**: Ensure compliance rules are properly tested before deployment
- **Identity Expiration**: Monitor and renew investor verifications

## Extending the System

### Adding New Compliance Rules

Extend the `Compliance` contract to add:
- Amount limits per transaction
- Daily/monthly transfer limits
- Blacklist functionality
- Geographic combination rules
- Reg S/Reg D specific requirements

### Custom Investor Roles

Define additional roles as needed:
- `"RETAIL"` - Retail investors
- `"INSTITUTIONAL"` - Institutional investors
- `"QUALIFIED"` - Qualified purchasers
- `"ELIGIBLE"` - Eligible contract participants

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Support

For questions or support, please open an issue in the repository.
