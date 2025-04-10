/*
/// Module: suikenyashilling
module suikenyashilling::suikenyashilling;
*/

#[allow(unused_use, duplicate_alias)]

module suikenyashilling::suikenyashilling {

    use sui::coin::{Self, TreasuryCap};
    use sui::url::{Self, Url};
    use std::ascii;
    use std::option;

    public struct SUIKENYASHILLING has drop {}

    fun init(witness: SUIKENYASHILLING, ctx: &mut TxContext) {
            // let icon_url = string::b"";
            let icon_string = ascii::string(b"https://i.ibb.co/zWYQgZtg/bafybeihnooccxn7wq22itfasapb6cwiyrnolcgozmoran3bwxlkdxwpkga.png");
            let icon_url = url::new_unsafe(icon_string);
            let (treasury, metadata) = coin::create_currency(
                    witness,
                    6,
                    b"sKSH",
                    b"SuiKenyaShilling",
                    b"The official sui kenya shilling (sKSH) on sui blockchain",
                    // Icon URL
                    option::some(icon_url),
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


