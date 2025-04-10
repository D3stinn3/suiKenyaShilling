# SuiKenyaShilling (sKSH) - Technical Documentation

## Overview

SuiKenyaShilling (sKSH) is a token implementation on the Sui blockchain with advanced tokenomics features including vesting schedules and airdrop capabilities. This module provides comprehensive tools for token distribution, lockups, and controlled release mechanics.

## Module Structure

```
suikenyashilling::suikenyashilling
```

## Token Specifications

- **Name**: SuiKenyaShilling
- **Symbol**: sKSH
- **Decimals**: 6
- **Description**: The official sui kenya shilling (sKSH) on sui blockchain
- **Icon URL**: https://i.ibb.co/zWYQgZtg/bafybeihnooccxn7wq22itfasapb6cwiyrnolcgozmoran3bwxlkdxwpkga.png

## Key Features

- Token creation and minting
- Admin-controlled operations
- Linear vesting schedules with cliff periods
- Airdrop distribution with expiration
- Batch minting for mass distribution

## Core Structures

### AdminCap

Administrative capability object that grants special permissions for protected functions.

```rust
public struct AdminCap has key, store {
    id: UID,
}
```

### VestingSchedule

Manages token vesting with configurable parameters.

```rust
public struct VestingSchedule has key, store {
    id: UID,
    beneficiary: address,
    total_amount: u64,
    released_amount: u64,
    start_time: u64,      // Unix timestamp
    end_time: u64,        // Unix timestamp
    cliff_time: u64,      // Unix timestamp for cliff
    interval: u64,        // Vesting interval in seconds
}
```

### VestingBalance

Holds the actual tokens being vested.

```rust
public struct VestingBalance has key {
    id: UID,
    balance: Balance<SUIKENYASHILLING>,
    vesting_id: ID,
}
```

### AirdropRegistry

Tracks airdrop recipients and their claims.

```rust
public struct AirdropRegistry has key {
    id: UID,
    recipients: Table<address, u64>, // Address -> Amount
    claimed: Table<address, bool>,   // Address -> Claimed status
    expires_at: u64,                 // Expiration timestamp
}
```

### AirdropBalance

Holds tokens allocated for airdrops.

```rust
public struct AirdropBalance has key {
    id: UID,
    balance: Balance<SUIKENYASHILLING>,
    registry_id: ID,
}
```

## Function Reference

### Token Management

#### `mint`

Mints new tokens to a specified recipient.

**Arguments:**
- `treasury_cap`: `&mut TreasuryCap<SUIKENYASHILLING>` - The treasury capability
- `amount`: `u64` - Amount of tokens to mint (in base units, 10^-6 sKSH)
- `recipient`: `address` - Address to receive the minted tokens
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function mint --args <treasury_cap_id> <amount> <recipient_address> --gas-budget 10000
```

### Vesting Management

#### `create_vesting`

Creates a new vesting schedule for a beneficiary.

**Arguments:**
- `_admin`: `&AdminCap` - Admin capability reference
- `treasury_cap`: `&mut TreasuryCap<SUIKENYASHILLING>` - The treasury capability
- `beneficiary`: `address` - Address that will receive the vested tokens
- `amount`: `u64` - Total amount of tokens to vest
- `start_time`: `u64` - Unix timestamp when vesting begins
- `duration`: `u64` - Vesting duration in seconds
- `cliff_duration`: `u64` - Cliff duration in seconds (from start_time)
- `interval`: `u64` - Vesting interval in seconds
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function create_vesting --args <admin_cap_id> <treasury_cap_id> <beneficiary_address> <amount> <start_time> <duration> <cliff_duration> <interval> --gas-budget 10000
```

#### `calculate_releasable`

Calculates how many tokens can be released for a given vesting schedule.

**Arguments:**
- `vesting`: `&VestingSchedule` - Reference to the vesting schedule
- `clock`: `&Clock` - Sui clock object

**Returns:** `u64` - The amount of tokens that can be released

#### `release_vested_tokens`

Releases vested tokens to the beneficiary based on the vesting schedule.

**Arguments:**
- `vesting`: `&mut VestingSchedule` - Mutable reference to the vesting schedule
- `vesting_balance`: `&mut VestingBalance` - Mutable reference to the vesting balance
- `clock`: `&Clock` - Sui clock object
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function release_vested_tokens --args <vesting_schedule_id> <vesting_balance_id> <clock_object_id> --gas-budget 10000
```

### Airdrop Management

#### `create_airdrop`

Creates an airdrop with a list of recipients and amounts.

**Arguments:**
- `_admin`: `&AdminCap` - Admin capability reference
- `treasury_cap`: `&mut TreasuryCap<SUIKENYASHILLING>` - The treasury capability
- `recipients`: `vector<address>` - Vector of recipient addresses
- `amounts`: `vector<u64>` - Vector of amounts corresponding to each recipient
- `expiration_time`: `u64` - Unix timestamp when the airdrop expires
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function create_airdrop --args <admin_cap_id> <treasury_cap_id> "[<address1>,<address2>]" "[<amount1>,<amount2>]" <expiration_time> --gas-budget 15000
```

#### `claim_airdrop`

Allows a recipient to claim their airdrop tokens.

**Arguments:**
- `registry`: `&mut AirdropRegistry` - Mutable reference to the airdrop registry
- `airdrop_balance`: `&mut AirdropBalance` - Mutable reference to the airdrop balance
- `clock`: `&Clock` - Sui clock object
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function claim_airdrop --args <registry_id> <airdrop_balance_id> <clock_object_id> --gas-budget 10000
```

#### `batch_mint`

Performs a batch mint operation to multiple recipients.

**Arguments:**
- `_admin`: `&AdminCap` - Admin capability reference
- `treasury_cap`: `&mut TreasuryCap<SUIKENYASHILLING>` - The treasury capability
- `recipients`: `vector<address>` - Vector of recipient addresses
- `amounts`: `vector<u64>` - Vector of amounts corresponding to each recipient
- `ctx`: `&mut TxContext` - Transaction context

**Example:**
```
sui client call --package <package_id> --module suikenyashilling --function batch_mint --args <admin_cap_id> <treasury_cap_id> "[<address1>,<address2>]" "[<amount1>,<amount2>]" --gas-budget 15000
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 1 | ENO_ADMIN_PERMISSION | Caller doesn't have admin permissions |
| 2 | EVESTING_NOT_STARTED | Vesting schedule hasn't started yet |
| 3 | ENOTHING_TO_RELEASE | No tokens available to release |
| 4 | ENOT_BENEFICIARY | Caller is not the vesting beneficiary |
| 5 | EINVALID_VESTING_SCHEDULE | Invalid vesting schedule parameters |
| 6 | EAIRDROP_ALREADY_CLAIMED | Airdrop already claimed by this address |
| 7 | EAIRDROP_NOT_ELIGIBLE | Address not eligible for this airdrop |
| 8 | EAIRDROP_EXPIRED | Airdrop has expired |
| 9 | EINVALID_RECIPIENT_LIST | Invalid recipient list parameters |

## Events

The module emits several events to track important operations:

- `VestingCreated` - When a new vesting schedule is created
- `VestingReleased` - When vested tokens are released to a beneficiary
- `AirdropRegistered` - When a new airdrop is registered
- `AirdropClaimed` - When an airdrop is claimed by a recipient

## Usage Notes

1. After module deployment, the `AdminCap` and `TreasuryCap` objects are transferred to the deployer's address.
2. The `Clock` object is a system object and must be passed to functions that require time checks.
3. All time-related parameters are in Unix timestamp format (seconds since epoch).
4. Vesting calculations are linear between the start and end times, with optional cliff periods.

## Security Considerations

- Only the admin can create vesting schedules and airdrops.
- Only the beneficiary can release vested tokens.
- Airdrop claims are validated against the registry to prevent double-claiming.
- Shared objects are used for vesting and airdrop resources to ensure proper access control.