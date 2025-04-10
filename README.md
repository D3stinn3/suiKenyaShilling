# sKSH Token (Sui Kenya Shilling Token)

**A shared commercial object used as a stablecoin and utility token across major transactional-based platforms.**

---

## 🧾 Overview

The **sKSH Token** represents a stable, digital form of the Kenyan Shilling deployed on the **Sui blockchain**. It is designed for use across decentralized applications (dApps) and payment systems, providing a secure and consistent value reference for users and developers alike.

---

## 🔧 Token Specifications

| Parameter            | Value                                                                 |
|----------------------|------------------------------------------------------------------------|
| **Blockchain**        | Sui Mainnet                                                           |
| **Module Name**       | `Sui_Kenya_Shilling`                                                  |
| **Mintable**          | Yes                                                                   |
| **Decimals**          | 6                                                                     |
| **Initial Supply**    | 1,000,000,000 (1 Billion sKSH)                                        |
| **Max Supply**        | 1,000,000,000 (Capped at 1 Billion)                                   |
| **Token Name**        | Sui Kenya Shilling                                                    |
| **Token Symbol**      | sKSH                                                                  |
| **Token Description** | The official Kenya Shilling stablecoin on the Sui blockchain.         |
| **Image URL**         | [IPFS Image](https://ipfs.algonode.dev/ipfs/bafybeihnooccxn7wq22itfasapb6cwiyrnolcgozmoran3bwxlkdxwpkga?optimizer=image&width=640) |
| **Ownership**         | `0x685146bc83d0de0de3fa42e5335c2fd6da123634969cdf0cd41288f41acb92c1` – [Eugene Wallet], Shared Owner Object |

---

## ⚠️ Important Notes

- **Metadata Mutability**: The token metadata is designed to be **mutable**. Ensure you **do not use the `freeze` function** if implementing metadata management on-chain.
- **Use Cases**: sKSH is ideal for digital payments, DeFi platforms, and tokenized commerce within the Kenyan ecosystem and beyond.

---

## 📈 Potential Integrations

- Digital wallets
- Payment gateways
- Decentralized Finance (DeFi)
- Cross-border remittances
- Stable payment rails for apps on the Sui network

---

## 📬 Contact

For integration or development inquiries, reach out to the sKSH token issuer via Eugene Wallet or associated contact channels.

---

## 💰 Tokenomics: Sizland Token (SZN)

**Total Supply**: 100,000,000 SKSH

### 🔄 Allocation Breakdown

| Category                        | % Allocation | Token Amount      | Status         | Notes |
|--------------------------------|--------------|-------------------|----------------|-------|
| **SKSH**                  | 30%          | 30,000,000 SKSH   | Locked 2 years | Annual release of 500,000 |
| **SKSH Company Reserve**    | 14%          | 14,000,000 SKSH    | Unlocked       | Used for ERP utility fees |
| **Founders**                   | 7%           | 7,000,000 SKSH     | Locked 1 year  | Annual release of 1,000,000 |
| **Management - Salaries**      | 7.35%        | 7,350,000 SKSH     | Vesting 6 months | Cliff dependent on staff expansion |
| **Employee Dividends**         | 4.41%        | 4,410,000 SKSH     | Locked Indefinitely | Long-term benefits |
| **Infrastructure/Partnerships**| 2.94%        | 2,940,000 SKSH     | Unlocked       | Controlled via governance |
| **Community (Total)**          | 34.3%        | 34,300,000 SKSH    | Mixed          | Subsections below |
| - VCs/Investors                | 3.43%        | 3,430,000 SKSH     | Presale        | $0.25 USD/token |
| - Presale                      | 3.43%        | 3,430,000 SKSH    | Presale        | $0.35 USD/token |
| - Launch                       | 10.29%       | 10,290,000 SKSH    | Launch         | $0.45 USD/token |
| - Liquidity                    | 10.29%       | 10,290,000 SKSH    | Liquid         | For DEX/CEX trading |
| - Marketing/Exchanges          | 6.86%        | 6,860,000 SKSH     | Operational    | Marketing + Launchpads |

---


## ⏳ Vesting & Cliff Design Guide for Developers (Sui Blockchain)

This section is crafted for Sui Move developers implementing lockups, cliffs, and vesting mechanics on the Sui blockchain.

### 📦 Airdrop Logic (Sui Move)

```move
public entry fun airdrop(
    sender: &signer,
    recipient: address,
    amount: u64,
    token: &mut Token
) {
    // Mint tokens to vesting object or direct recipient based on policy
    transfer::mint_to_recipient(sender, recipient, amount, token);
}
```

- Prefer wrapping recipient's tokens in a **vesting object** if lockup is required.
- Emit events for indexing and analytics.

---

### ⏳ Vesting Object Structure

```move
struct VestingSchedule has key {
    beneficiary: address,
    total_amount: u64,
    released: u64,
    start_time: u64,
    duration: u64,
    cliff: u64,
    created_at: u64,
}
```

- Store this object on-chain and index it using `table`.
- Reference Sui’s `Clock` object to get block timestamps (`clock::now_seconds()`).

---

### 🪜 Cliff and Vesting Claim Logic

```move
public fun claim_tokens(
    clock: &Clock,
    vesting: &mut VestingSchedule,
    token: &mut Token
): Result<(), E> {
    let current_time = clock::now_seconds(clock);

    if (current_time < vesting.created_at + vesting.cliff) {
        return Err(error::new(E::CliffNotReached));
    }

    let elapsed = current_time - vesting.start_time;
    let vested = min(
        vesting.total_amount,
        vesting.total_amount * elapsed / vesting.duration
    );
    let to_release = vested - vesting.released;
    vesting.released = vested;

    transfer::mint_to_recipient(...); // Add logic here

    Ok(())
}
```

---

### 🛡️ Governance and Control

Use `Shared` or `GovernanceCap` to:
- Unlock or pause token streams
- Trigger cliffs based on milestones (e.g., company staff growth)
- Modify or revoke vesting schedules (if necessary)

---

### 🧠 Notes for Sui Development

- Store `VestingSchedule` as objects — leverage Sui’s object model.
- Use modules and capabilities for secure minting/claiming logic.
- Consider gas implications for large batch vesting claims.
- Use events for transparency and traceability.
## 🧠 Developer Notes

- Consider integrating with [OpenZeppelin's Vesting Contracts](https://docs.openzeppelin.com/contracts/4.x/api/token/ERC20#TokenVesting) as a base.
- Add admin functionality to modify vesting in case of strategic pivots.
- Ensure transparency: Allow public read functions for schedules and claimable balances.
- Governance functions should control critical release operations (e.g., unlocking for strategic partnerships).

