module MetaGame::boat_ticket {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::coin::{Self, Coin, destroy_zero};
    use std::string::{String, utf8};
    use sui::sui::{Self, SUI};
    use sui::package;
    use sui::balance::{Self, Balance};
    use sui::display;
    use std::vector;
    use sui::pay;
    use MetaGame::swap::{Self, SwapGlobal};
    friend MetaGame::airdrop;

    const DEFAULT_LINK: vector<u8> = b"https://shui.one";
    const DEFAULT_IMAGE_URL: vector<u8> = b"https://bafybeibzoi4kzr4gg75zhso5jespxnwespyfyakemrwibqorjczkn23vpi.ipfs.nftstorage.link/NFT-CARD1.png";
    const DESCRIPTION: vector<u8> = b"Airship to meta masrs";
    const PROJECT_URL: vector<u8> = b"https://shui.one/game/#/";
    const CREATOR: vector<u8> = b"metaGame";
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;
    const ERR_SWAP_MIN_ONE_SUI:u64 = 0x004;
    const ERR_NO_PERMISSION:u64 = 0x005;

    struct BOAT_TICKET has drop {}
    struct BoatTicket has key, store {
        id:UID,
        name:String,
        index:u64,
        whitelist_claimed:bool
    }

    struct BoatTicketGlobal has key {
        id: UID,
        balance_SUI: Balance<sui::SUI>,
        creator: address,
        num:u64
    }

    public fun get_index(ticket: &BoatTicket): u64 {
        ticket.index
    }

    public fun get_name(ticket: &BoatTicket): String {
        ticket.name
    }

    #[lint_allow(self_transfer)]
    public entry fun buy_ticket(global:&mut BoatTicketGlobal, swapGlobal: &mut SwapGlobal, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        let recepient = tx_context::sender(ctx);
        let price = 5;
        let merged_coin = vector::pop_back(&mut coins);
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
        let ticket = BoatTicket {
            id:object::new(ctx),
            name:utf8(b"Airship"),
            index:global.num,
            whitelist_claimed: false
        };
        global.num = global.num + 1;
        transfer::transfer(ticket, tx_context::sender(ctx));
        swap::set_whitelist(swapGlobal, ctx);
    }

    #[test_only]
    #[lint_allow(self_transfer)]
    public entry fun claim_ticket(global:&mut BoatTicketGlobal, ctx:&mut TxContext) {
        let ticket = BoatTicket {
            id:object::new(ctx),
            name:utf8(b"Airship"),
            index:global.num,
            whitelist_claimed: false
        };
        global.num = global.num + 1;
        transfer::transfer(ticket, tx_context::sender(ctx));
    }

    #[allow(unused_function)]
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

    #[lint_allow(self_transfer)]
    public entry fun withdraw_sui(global: &mut BoatTicketGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SUI, amount);
        let sui = coin::from_balance(balance, ctx);
        transfer::public_transfer(sui, tx_context::sender(ctx));
    }

    public(friend) fun record_white_list_clamed(ticket:&mut BoatTicket) {
        ticket.whitelist_claimed = true;
    }

    public entry fun is_claimed(ticket:&BoatTicket) : bool{
        ticket.whitelist_claimed
    }

    public fun change_owner(global:&mut BoatTicketGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }
}