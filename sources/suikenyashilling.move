#[allow(unused_const,duplicate_alias,unused_use)]
module suikenyashilling::suikenyashilling {

    use std::ascii;
    use std::string;
    use std::option;
    use std::vector;
    use sui::coin::{Self, TreasuryCap};
    use sui::url;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::event;

    public struct SUIKENYASHILLING has drop {}

    // Capability for the module owner
    public struct AdminCap has key, store {
        id: UID,
    }

    // Struct for managing vesting schedules
    public struct VestingSchedule has key, store {
        id: UID,
        beneficiary: address,
        total_amount: u64,
        released_amount: u64,
        start_time: u64,      // Unix timestamp
        end_time: u64,        // Unix timestamp
        cliff_time: u64,      // Unix timestamp for cliff
        interval: u64,        // Vesting interval in seconds (e.g., 30 days)
    }

    // Balance object holding vested funds
    public struct VestingBalance has key {
        id: UID,
        balance: Balance<SUIKENYASHILLING>,
        vesting_id: ID,
    }

    // Struct for managing airdrops
    public struct AirdropRegistry has key {
        id: UID,
        recipients: Table<address, u64>, // Address -> Amount
        claimed: Table<address, bool>,   // Address -> Claimed status
        expires_at: u64,                 // Expiration timestamp
    }

    // Balance object holding airdrop funds
    public struct AirdropBalance has key {
        id: UID,
        balance: Balance<SUIKENYASHILLING>,
        registry_id: ID,
    }

    // Events
    public struct VestingCreated has copy, drop {
        beneficiary: address,
        total_amount: u64,
        start_time: u64,
        end_time: u64,
    }

    public struct VestingReleased has copy, drop {
        beneficiary: address,
        amount: u64,
    }

    public struct AirdropRegistered has copy, drop {
        recipient_count: u64,
        total_amount: u64,
        expires_at: u64,
    }

    public struct AirdropClaimed has copy, drop {
        recipient: address,
        amount: u64,
    }

    // Error codes
    const ENO_ADMIN_PERMISSION: u64 = 1;
    const EVESTING_NOT_STARTED: u64 = 2;
    const ENOTHING_TO_RELEASE: u64 = 3;
    const ENOT_BENEFICIARY: u64 = 4;
    const EINVALID_VESTING_SCHEDULE: u64 = 5;
    const EAIRDROP_ALREADY_CLAIMED: u64 = 6;
    const EAIRDROP_NOT_ELIGIBLE: u64 = 7;
    const EAIRDROP_EXPIRED: u64 = 8;
    const EINVALID_RECIPIENT_LIST: u64 = 9;

    fun init(witness: SUIKENYASHILLING, ctx: &mut TxContext) {
        let icon_string = ascii::string(b"https://i.ibb.co/zWYQgZtg/bafybeihnooccxn7wq22itfasapb6cwiyrnolcgozmoran3bwxlkdxwpkga.png");
        let icon_url = url::new_unsafe(icon_string);
        let (treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"sKSH",
            b"SuiKenyaShilling",
            b"The official sui kenya shilling (sKSH) on sui blockchain",
            option::some(icon_url),
            ctx,
        );
        
        // Create and transfer admin capability
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
    }

    // Mint tokens
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<SUIKENYASHILLING>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    // Create a new vesting schedule
    public entry fun create_vesting(
        _admin: &AdminCap,
        treasury_cap: &mut TreasuryCap<SUIKENYASHILLING>,
        beneficiary: address,
        amount: u64,
        start_time: u64,
        duration: u64,
        cliff_duration: u64,
        interval: u64,
        ctx: &mut TxContext,
    ) {
        assert!(duration > 0 && interval > 0, EINVALID_VESTING_SCHEDULE);
        
        // Calculate times
        let end_time = start_time + duration;
        let cliff_time = start_time + cliff_duration;
        
        // Create vesting schedule
        let vesting_schedule = VestingSchedule {
            id: object::new(ctx),
            beneficiary,
            total_amount: amount,
            released_amount: 0,
            start_time,
            end_time,
            cliff_time,
            interval,
        };

        // Mint tokens to be locked in vesting schedule
        let vested_coins = coin::mint(treasury_cap, amount, ctx);
        let vested_balance = coin::into_balance(vested_coins);
        
        // Create a balance object for the vesting schedule
        let vesting_balance = VestingBalance {
            id: object::new(ctx),
            balance: vested_balance,
            vesting_id: object::id(&vesting_schedule),
        };

        // Emit event
        event::emit(VestingCreated {
            beneficiary,
            total_amount: amount,
            start_time,
            end_time,
        });

        // Transfer objects
        transfer::share_object(vesting_schedule);
        transfer::share_object(vesting_balance);
    }

    // Calculate releasable amount based on vesting schedule
    public fun calculate_releasable(
        vesting: &VestingSchedule, 
        clock: &Clock
    ): u64 {
        let current_time = clock::timestamp_ms(clock) / 1000; // Convert ms to seconds
        
        // If current time is before cliff, nothing can be released
        if (current_time < vesting.cliff_time) return 0;

        // If after end time, all can be released
        if (current_time >= vesting.end_time) return vesting.total_amount - vesting.released_amount;

        // Linear vesting calculation
        let time_since_start = current_time - vesting.start_time;
        let total_vesting_time = vesting.end_time - vesting.start_time;
        
        let vested_amount = (vesting.total_amount * time_since_start) / total_vesting_time;
        let releasable = vested_amount - vesting.released_amount;
        
        releasable
    }

    // Release vested tokens
    public entry fun release_vested_tokens(
        vesting: &mut VestingSchedule,
        vesting_balance: &mut VestingBalance,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        // Check if the caller is the beneficiary
        assert!(tx_context::sender(ctx) == vesting.beneficiary, ENOT_BENEFICIARY);
        
        // Check if vesting ID matches
        assert!(object::id(vesting) == vesting_balance.vesting_id, EINVALID_VESTING_SCHEDULE);
        
        // Calculate releasable amount
        let releasable = calculate_releasable(vesting, clock);
        assert!(releasable > 0, ENOTHING_TO_RELEASE);
        
        // Update released amount
        vesting.released_amount = vesting.released_amount + releasable;
        
        // Create and transfer coins
        let coin = coin::from_balance(balance::split(&mut vesting_balance.balance, releasable), ctx);
        transfer::public_transfer(coin, vesting.beneficiary);
        
        // Emit event
        event::emit(VestingReleased {
            beneficiary: vesting.beneficiary,
            amount: releasable,
        });
    }

    // Create an airdrop registry
    public entry fun create_airdrop(
        _admin: &AdminCap,
        treasury_cap: &mut TreasuryCap<SUIKENYASHILLING>,
        recipients: vector<address>,
        amounts: vector<u64>,
        expiration_time: u64,
        ctx: &mut TxContext,
    ) {
        // Validate inputs
        let recipients_len = vector::length(&recipients);
        assert!(recipients_len > 0, EINVALID_RECIPIENT_LIST);
        assert!(recipients_len == vector::length(&amounts), EINVALID_RECIPIENT_LIST);
        
        // Create registry tables
        let mut recipients_table = table::new<address, u64>(ctx);
        let mut claimed_table = table::new<address, bool>(ctx);
        
        // Calculate total airdrop amount
        let mut total_amount = 0u64;
        let mut i = 0;
        while (i < recipients_len) {
            let recipient = *vector::borrow(&recipients, i);
            let amount = *vector::borrow(&amounts, i);
            
            table::add(&mut recipients_table, recipient, amount);
            table::add(&mut claimed_table, recipient, false);
            total_amount = total_amount + amount;
            
            i = i + 1;
        };
        
        // Create the registry
        let airdrop_registry = AirdropRegistry {
            id: object::new(ctx),
            recipients: recipients_table,
            claimed: claimed_table,
            expires_at: expiration_time,
        };
        
        // Mint tokens for the airdrop
        let airdrop_coins = coin::mint(treasury_cap, total_amount, ctx);
        let airdrop_balance = AirdropBalance {
            id: object::new(ctx),
            balance: coin::into_balance(airdrop_coins),
            registry_id: object::id(&airdrop_registry),
        };
        
        // Emit event
        event::emit(AirdropRegistered {
            recipient_count: recipients_len,
            total_amount,
            expires_at: expiration_time,
        });
        
        // Share objects
        transfer::share_object(airdrop_registry);
        transfer::share_object(airdrop_balance);
    }
    
    // Claim airdrop tokens
    public entry fun claim_airdrop(
        registry: &mut AirdropRegistry,
        airdrop_balance: &mut AirdropBalance,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let caller = tx_context::sender(ctx);
        
        // Check if registry ID matches
        assert!(object::id(registry) == airdrop_balance.registry_id, EINVALID_RECIPIENT_LIST);
        
        // Check if airdrop is still valid
        assert!(clock::timestamp_ms(clock) / 1000 <= registry.expires_at, EAIRDROP_EXPIRED);
        
        // Check if caller is eligible
        assert!(table::contains(&registry.recipients, caller), EAIRDROP_NOT_ELIGIBLE);
        
        // Check if already claimed
        assert!(!*table::borrow(&registry.claimed, caller), EAIRDROP_ALREADY_CLAIMED);
        
        // Get amount
        let amount = *table::borrow(&registry.recipients, caller);
        
        // Mark as claimed
        *table::borrow_mut(&mut registry.claimed, caller) = true;
        
        // Transfer tokens
        let coin = coin::from_balance(balance::split(&mut airdrop_balance.balance, amount), ctx);
        transfer::public_transfer(coin, caller);
        
        // Emit event
        event::emit(AirdropClaimed {
            recipient: caller,
            amount,
        });
    }
    
    // Batch mint - useful for airdrops without claiming process
    public entry fun batch_mint(
        _admin: &AdminCap,
        treasury_cap: &mut TreasuryCap<SUIKENYASHILLING>,
        recipients: vector<address>,
        amounts: vector<u64>,
        ctx: &mut TxContext,
    ) {
        // Validate inputs
        let recipients_len = vector::length(&recipients);
        assert!(recipients_len > 0, EINVALID_RECIPIENT_LIST);
        assert!(recipients_len == vector::length(&amounts), EINVALID_RECIPIENT_LIST);
        
        let mut i = 0;
        while (i < recipients_len) {
            let recipient = *vector::borrow(&recipients, i);
            let amount = *vector::borrow(&amounts, i);
            
            // Mint and transfer
            let coin = coin::mint(treasury_cap, amount, ctx);
            transfer::public_transfer(coin, recipient);
            
            i = i + 1;
        };
    }
}