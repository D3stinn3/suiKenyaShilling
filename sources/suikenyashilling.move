/*
/// Module: suikenyashilling
module suikenyashilling::suikenyashilling;
*/

module suikenyashilling::suikenyashilling {

    use sui::coin::{Self, TreasuryCap};

    public struct SUIKENYASHILLING has drop {}

    fun init(witness: SUIKENYASHILLING, ctx: &mut TxContext) {
            let (treasury, metadata) = coin::create_currency(
                    witness,
                    6,
                    b"sKSH",
                    b"SuiKenyaShilling",
                    b"The official sui kenya shilling (sKSH) on sui blockchain",
                    // Icon URL
                    option::none(),
                    ctx,
            );
            transfer::public_freeze_object(metadata);
            transfer::public_transfer(treasury, ctx.sender())
    }

    public fun mint(
            treasury_cap: &mut TreasuryCap<SUIKENYASHILLING>,
            amount: u64,
            recipient: address,
            ctx: &mut TxContext,
    ) {
            let coin = coin::mint(treasury_cap, amount, ctx);
            transfer::public_transfer(coin, recipient)
    }
}

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


