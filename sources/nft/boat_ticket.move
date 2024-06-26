module MetaGame::boat_ticket {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::coin::{Self, Coin, destroy_zero};
    use std::string::{String, utf8};
    use sui::package;
    use sui::balance::{Self, Balance};
    use sui::display;
    use std::vector;
    use sui::pay;
    use sui::sui::{SUI};
    use MetaGame::shui;
    friend MetaGame::airdrop;

    const DEFAULT_LINK: vector<u8> = b"https://shui.game";
    const DEFAULT_IMAGE_URL: vector<u8> = b"https://bafybeibym77qxeq724kkqnkq2mz2i63e423ppjxgwnfcnqmhbh65qbvueu.ipfs.nftstorage.link/ship_card.png";
    const DESCRIPTION: vector<u8> = b"AirShip to meta masrs";
    const PROJECT_URL: vector<u8> = b"https://shui.game/";
    const CREATOR: vector<u8> = b"metaGame";
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;
    const ERR_SWAP_MIN_ONE_SUI:u64 = 0x004;
    const ERR_NO_PERMISSION:u64 = 0x005;
    const ERR_HAS_REACH_LIMIT: u64 = 0x006;
    const MAX_TICKET_NUM:u64 = 4000;

    struct BOAT_TICKET has drop {}
    struct BoatTicket has key, store {
        id:UID,
        name:String,
        index:u64,
        whitelist_claimed:bool
    }

    struct BoatTicketGlobal has key {
        id: UID,
        balance_SUI: Balance<SUI>,
        creator: address,
        num:u64
    }

    public fun get_index(ticket: &BoatTicket): u64 {
        ticket.index
    }

    public fun get_name(ticket: &BoatTicket): String {
        ticket.name
    }

    public entry fun buy_ticket(global:&mut BoatTicketGlobal, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        let recepient = tx_context::sender(ctx);
        let price = 25;
        let merged_coin = vector::pop_back(&mut coins);
        assert!(global.num < MAX_TICKET_NUM, ERR_HAS_REACH_LIMIT);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= price * AMOUNT_DECIMAL, ERR_SWAP_MIN_ONE_SUI);
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, price * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        global.num = global.num + 1;
        let ticket = BoatTicket {
            id:object::new(ctx),
            name:utf8(b"Shui Meta Ticket"),
            index:global.num,
            whitelist_claimed: false
        };
        transfer::transfer(ticket, tx_context::sender(ctx));
    }

    #[test_only]
    public entry fun claim_ticket(global:&mut BoatTicketGlobal, ctx:&mut TxContext) {
        let ticket = BoatTicket {
            id:object::new(ctx),
            name:utf8(b"Shui Meta Ticket"),
            index:global.num,
            whitelist_claimed: false
        };
        global.num = global.num + 1;
        transfer::transfer(ticket, tx_context::sender(ctx));
    }

    fun init(otw: BOAT_TICKET, ctx: &mut TxContext) {
        // https://docs.sui.io/build/sui-object-display

        let keys = vector[
            // A name for the object. The name is displayed when users view the object.
            utf8(b"name"),
            // A description for the object. The description is displayed when users view the object.
            utf8(b"description"),
            // A link to the object to use in an application.
            utf8(b"link"),
            // A URL or a blob with the image for the object.
            utf8(b"image_url"),
            // A link to a website associated with the object or creator.
            utf8(b"project_url"),
            // A string that indicates the object creator.
            utf8(b"creator")
        ];
        let values = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(DEFAULT_IMAGE_URL),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        // Get a new `Display` object for the `SuiCat` type.
        let display = display::new_with_fields<BoatTicket>(
            &publisher, keys, values, ctx
        );

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);
        transfer::public_transfer(publisher, sender(ctx));
        transfer::public_transfer(display, sender(ctx));

        let global = BoatTicketGlobal {
            id: object::new(ctx),
            balance_SUI: balance::zero(), 
            creator: tx_context::sender(ctx),
            num:0
        };
        transfer::share_object(global);
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = BoatTicketGlobal {
            id: object::new(ctx),
            balance_SUI: balance::zero(), 
            creator: tx_context::sender(ctx),
            num:0
        };
        transfer::share_object(global);
    }

    public fun get_boat_num(global:&BoatTicketGlobal):u64 {
        global.num
    }

    public entry fun withdraw_shui(global: &mut BoatTicketGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SUI, amount);
        let shui = coin::from_balance(balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }

    public(friend) fun record_white_list_clamed(ticket:&mut BoatTicket) {
        ticket.whitelist_claimed = true;
    }

    public(friend) fun is_claimed(ticket:&BoatTicket) : bool {
        ticket.whitelist_claimed
    }

    public fun get_is_ticket_claimed(ticket:&BoatTicket) : u64 {
        if (ticket.whitelist_claimed) {
            1
        } else {
            0
        }
    }
}