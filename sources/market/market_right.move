module MetaGame::market_right {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::display;
    use sui::coin::{Self, Coin, destroy_zero};
    use sui::package;
    use std::string::{String, utf8, Self};
    use std::vector;
    use sui::sui::{SUI};
    use sui::pay;
    use sui::balance::{Self, Balance};
    use MetaGame::shui::{SHUI};
    friend MetaGame::tree_of_life;
    friend MetaGame::market;
    
    const DEFAULT_LINK: vector<u8> = b"https://shui.game";
    const IMAGE_URL_NFT_20: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st50.png";
    const IMAGE_URL_NFT_15: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st100.png";
    const IMAGE_URL_NFT_10: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st500.png";
    const IMAGE_URL_NFT_5: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_NFT_0: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";

    const IMAGE_URL_GAME_25: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st50.png";
    const IMAGE_URL_GAME_20: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st100.png";
    const IMAGE_URL_GAME_10: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st500.png";
    const IMAGE_URL_GAME_5: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_GAME_3: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";
    const IMAGE_URL_GAME_2: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_GAME_0: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";
    const DESCRIPTION: vector<u8> = b"shui metagame market fee rights, owner can gain gas fee from it cyclically";
    const PROJECT_URL: vector<u8> = b"https://shui.game/game/#/";
    const CREATOR: vector<u8> = b"metaGame";

    const ERR_NO_PERMISSION: u64 = 0x001;
    const ERR_EXCEED_ISSUE_NUM: u64 = 0x002;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    struct MARKET_RIGHT has drop {}

    struct MarketRightGlobal has key {
        id: UID,
        culmulate_SHUI: u64,
        culmulate_SUI: u64,
        balance_SHUI: Balance<SHUI>,
        balance_SUI: Balance<SUI>,

        nft_20_issued: u64,
        nft_15_issued: u64,
        nft_10_issued: u64,
        nft_5_issued: u64,
        nft_0_issued: u64,

        game_25_issued: u64,
        game_20_issued: u64,
        game_10_issued: u64,
        game_5_issued: u64,
        game_3_issued: u64,
        game_2_issued: u64,
        game_0_issued: u64,

        creator: address,
        version: u64
    }

    // nft gas fee rights
    struct MARKET_RIGHT_NFT20 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_NFT15 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_NFT10 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_NFT5 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_NFT0 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }

    // gamefi gas fee rights
    struct MARKET_RIGHT_GAME25 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME20 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME10 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME5 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME3 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME2 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }
    struct MARKET_RIGHT_GAME0 has key, store {
        id:UID,
        name:String,
        claimed_sui_amount:u64,
        claimed_shui_amount:u64
    }

    #[allow(unused_function)]
    fun init(otw: MARKET_RIGHT, ctx: &mut TxContext) {
        let global = MarketRightGlobal {
            id: object::new(ctx),
            culmulate_SHUI: 0,
            culmulate_SUI: 0,
            balance_SHUI: balance::zero(),
            balance_SUI: balance::zero(),
            nft_20_issued:0,
            nft_15_issued:0,
            nft_10_issued:0,
            nft_5_issued: 0,
            nft_0_issued: 0,

            game_25_issued:0,
            game_20_issued:0,
            game_10_issued:0,
            game_5_issued: 0,
            game_3_issued: 0,
            game_2_issued: 0,
            game_0_issued: 0,
            creator: tx_context::sender(ctx),
            version: 0
        };
        transfer::share_object(global);

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
        let values_nft_20 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_20),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_15 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_15),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_10 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_10),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_5 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_0 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_0),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        let values_game_25 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_20),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_20 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_15),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_10 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_10),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_5 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_3 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_2 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_0 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_0),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        let publisher = package::claim(otw, ctx);

        let display_nft_20 = display::new_with_fields<MARKET_RIGHT_NFT20>(
            &publisher, keys, values_nft_20, ctx
        );
        display::update_version(&mut display_nft_20);
        transfer::public_transfer(display_nft_20, sender(ctx));

        let display_nft_15 = display::new_with_fields<MARKET_RIGHT_NFT15>(
            &publisher, keys, values_nft_15, ctx
        );
        display::update_version(&mut display_nft_15);
        transfer::public_transfer(display_nft_15, sender(ctx));

        let display_nft_10 = display::new_with_fields<MARKET_RIGHT_NFT10>(
            &publisher, keys, values_nft_10, ctx
        );
        display::update_version(&mut display_nft_10);
        transfer::public_transfer(display_nft_10, sender(ctx));

        let display_nft_5 = display::new_with_fields<MARKET_RIGHT_NFT5>(
            &publisher, keys, values_nft_5, ctx
        );
        display::update_version(&mut display_nft_5);
        transfer::public_transfer(display_nft_5, sender(ctx));

        let display_nft_0 = display::new_with_fields<MARKET_RIGHT_NFT0>(
            &publisher, keys, values_nft_0, ctx
        );
        display::update_version(&mut display_nft_0);
        transfer::public_transfer(display_nft_0, sender(ctx));



        let display_game_25 = display::new_with_fields<MARKET_RIGHT_GAME25>(
            &publisher, keys, values_game_25, ctx
        );
        display::update_version(&mut display_game_25);
        transfer::public_transfer(display_game_25, sender(ctx));

        let display_game_20 = display::new_with_fields<MARKET_RIGHT_GAME20>(
            &publisher, keys, values_game_20, ctx
        );
        display::update_version(&mut display_game_20);
        transfer::public_transfer(display_game_20, sender(ctx));

        let display_game_10 = display::new_with_fields<MARKET_RIGHT_GAME10>(
            &publisher, keys, values_game_10, ctx
        );
        display::update_version(&mut display_game_10);
        transfer::public_transfer(display_game_10, sender(ctx));

        let display_game_5 = display::new_with_fields<MARKET_RIGHT_GAME5>(
            &publisher, keys, values_game_5, ctx
        );
        display::update_version(&mut display_game_5);
        transfer::public_transfer(display_game_5, sender(ctx));

        let display_game_3 = display::new_with_fields<MARKET_RIGHT_GAME3>(
            &publisher, keys, values_game_3, ctx
        );
        display::update_version(&mut display_game_3);
        transfer::public_transfer(display_game_3, sender(ctx));

        let display_game_2 = display::new_with_fields<MARKET_RIGHT_GAME2>(
            &publisher, keys, values_game_2, ctx
        );
        display::update_version(&mut display_game_2);
        transfer::public_transfer(display_game_2, sender(ctx));

        let display_game_0 = display::new_with_fields<MARKET_RIGHT_GAME0>(
            &publisher, keys, values_game_0, ctx
        );
        display::update_version(&mut display_game_0);
        transfer::public_transfer(display_game_0, sender(ctx));
        
        transfer::public_transfer(publisher, sender(ctx));
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = MarketRightGlobal {
            id: object::new(ctx),
            culmulate_SHUI: 0,
            culmulate_SUI: 0,
            balance_SHUI: balance::zero(),
            balance_SUI: balance::zero(),
            nft_20_issued:0,
            nft_15_issued:0,
            nft_10_issued:0,
            nft_5_issued: 0,
            nft_0_issued: 0,

            game_25_issued:0,
            game_20_issued:0,
            game_10_issued:0,
            game_5_issued: 0,
            game_3_issued: 0,
            game_2_issued: 0,
            game_0_issued: 0,
            creator: tx_context::sender(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    public(friend) fun into_gas_pool_SHUI(global: &mut MarketRightGlobal, gas: balance::Balance<SHUI>) {
        global.culmulate_SHUI = global.culmulate_SHUI + balance::value(&gas);
        balance::join(&mut global.balance_SHUI, gas);
    }

    public(friend) fun into_gas_pool_SUI(global: &mut MarketRightGlobal, gas: balance::Balance<SUI>) {
        global.culmulate_SUI = global.culmulate_SUI + balance::value(&gas);
        balance::join(&mut global.balance_SUI, gas);
    }

    public fun issue_nft_right_20(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.nft_20_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_NFT20 {
            id:object::new(ctx),
            name:utf8(b"SHUI-NFT 20"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.nft_20_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_nft_right_15(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.nft_15_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_NFT15 {
            id:object::new(ctx),
            name:utf8(b"SHUI-NFT 15"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.nft_15_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_nft_right_10(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.nft_10_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_NFT10 {
            id:object::new(ctx),
            name:utf8(b"SHUI-NFT 10"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.nft_10_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_nft_right_5(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.nft_5_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_NFT5 {
            id:object::new(ctx),
            name:utf8(b"SHUI-NFT 5"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.nft_5_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_25(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_25_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME25 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 25"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_25_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_20(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_20_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME20 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 20"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_20_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_10(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_10_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME10 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 10"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_10_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_5(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_5_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME5 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 5"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_5_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_3(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_3_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME3 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 3"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_3_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public fun issue_game_right_2(global: &mut MarketRightGlobal, receiver:address, ctx:&mut TxContext) {
        assert!(global.creator == @manager, ERR_NO_PERMISSION);
        assert!(global.game_2_issued == 0, ERR_EXCEED_ISSUE_NUM);
        let nft = MARKET_RIGHT_GAME2 {
            id:object::new(ctx),
            name:utf8(b"SHUI-GameFi 2"),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_2_issued = 1;
        transfer::public_transfer(nft, receiver);
    }

    public entry fun buy_nft_right_0(global: &mut MarketRightGlobal, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        assert!(global.nft_0_issued <= 500, ERR_EXCEED_ISSUE_NUM);
        let price = 888;
        let receiver = tx_context::sender(ctx);
        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        let name:vector<u8> = *string::bytes(&string::utf8(b"NFT-TOKEN "));
        vector::append(&mut name, numbers_to_ascii_vector(global.nft_0_issued + 1));
        let nft = MARKET_RIGHT_NFT0 {
            id:object::new(ctx),
            name:utf8(name),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.nft_0_issued = global.nft_0_issued + 1;
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, price * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, receiver)
        } else {
            destroy_zero(merged_coin)
        };
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    fun numbers_to_ascii_vector(val: u64): vector<u8> {
        let vec = vector<u8>[];
        loop {
            let b = val % 10;
            vector::push_back(&mut vec, (48 + b as u8));
            val = val / 10;
            if (val <= 0) break;
        };
        vector::reverse(&mut vec);
        vec
    }

    public entry fun buy_game_right_0(global: &mut MarketRightGlobal, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        assert!(global.game_0_issued <= 500, ERR_EXCEED_ISSUE_NUM);
        let price = 888;
        let receiver = tx_context::sender(ctx);
        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        let name:vector<u8> = *string::bytes(&string::utf8(b"GameFi-TOKEN "));
        vector::append(&mut name, numbers_to_ascii_vector(global.game_0_issued + 1));
        let nft = MARKET_RIGHT_GAME0 {
            id:object::new(ctx),
            name: utf8(name),
            claimed_sui_amount:0,
            claimed_shui_amount:0
        };
        global.game_0_issued = global.game_0_issued + 1;
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, price * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, receiver)
        } else {
            destroy_zero(merged_coin)
        };
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    public fun withdraw_sui(global: &mut MarketRightGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == @manager, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SUI, amount);
        let sui = coin::from_balance(balance, ctx);
        transfer::public_transfer(sui, tx_context::sender(ctx));
    }

    public fun withdraw_shui(global: &mut MarketRightGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == @manager, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }

    public fun claimed_nft_20(global: &mut MarketRightGlobal, nft: &mut MARKET_RIGHT_NFT20, ctx: &mut TxContext) {
        let total_shui_amount = global.culmulate_SHUI;
        let total_sui_amount = global.culmulate_SUI;
        if (total_shui_amount / 5 > nft.claimed_shui_amount) {
            let left_amount = total_shui_amount / 5 - nft.claimed_shui_amount;
            nft.claimed_shui_amount = nft.claimed_shui_amount + left_amount;
            let balance = balance::split(&mut global.balance_SHUI, left_amount);
            let shui = coin::from_balance(balance, ctx);
            transfer::public_transfer(shui, tx_context::sender(ctx));
        };

        if (total_sui_amount / 5 > nft.claimed_sui_amount) {
            let left_amount = total_sui_amount / 5 - nft.claimed_sui_amount;
            nft.claimed_sui_amount = nft.claimed_sui_amount + left_amount;
            let balance = balance::split(&mut global.balance_SUI, left_amount);
            let sui = coin::from_balance(balance, ctx);
            transfer::public_transfer(sui, tx_context::sender(ctx));
        };
    }
}