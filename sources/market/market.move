module MetaGame::market {
    use std::ascii;
    use std::string::{Self, String, utf8};
    use std::vector;
    use sui::linked_table::{Self, LinkedTable};
    use sui::coin::{Self, Coin, value, destroy_zero};
    use sui::object::{UID, Self};
    use sui::sui::SUI;
    use std::type_name::{Self, into_string};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::address;
    use sui::bag::{Self};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self};
    use sui::clock::{Self, Clock};
    use MetaGame::metaIdentity::{Self, MetaIdentity};
    use MetaGame::tree_of_life::Self;
    use MetaGame::shui::{Self, SHUI};
    use MetaGame::market_right;
    use sui::event;

    const ERR_SALES_NOT_EXIST: u64 = 0x002;
    const ERR_NOT_OWNER: u64 = 0x003;
    const ERR_EXCEED_MAX_ON_SALE_NUM: u64 = 0x004;
    const ERR_INVALID_COIN:u64 = 0x005;
    const ERR_CAN_NOT_BUY_YOUR_ITEM:u64 = 0x006;
    const ERR_NO_PERMISSION: u64 = 0x007;
    const ERR_INVALID_VERSION:u64 = 0x008;
    const DAY_IN_MS: u64 = 86_400_000;
    const VERSION: u64 = 0;

    struct MARKET has drop {}

    struct MarketGlobal has key {
        id: UID,
        balance_SHUI: Balance<shui::SHUI>,
        balance_SUI: Balance<SUI>,
        creator: address,

        // metaId -> table<objid -> OnSaleInfo>
        game_sales : LinkedTable<u64, vector<OnSale>>,
        version: u64
    }

    struct TransactionRecord has copy, drop {
        seller:address,
        buyer:address,
        name:String,
        num:u64,
        price:u64,
        price_gas:u64,
        type:String,
        coinType:String,
        time:u64
    }

    struct OnSale has key, store {
        id: UID,
        name: String,
        num: u64,
        price: u64,
        coinType: String,
        owner: address,
        metaId: u64,
        type: String,
        onsale_time: u64,

        // at most store one obejct
        bag: bag::Bag,
        nftType: String,
        nft_addr: address
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = MarketGlobal {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            balance_SUI: balance::zero(),
            game_sales: linked_table::new<u64, vector<OnSale>>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    #[allow(unused_function)]
    fun init(_witness: MARKET, ctx: &mut TxContext) {
        let global = MarketGlobal {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            balance_SUI: balance::zero(),

            // metaId -> sales
            game_sales: linked_table::new<u64, vector<OnSale>>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    fun new_nft_sale<Nft:key + store>(metaId:u64, name:String, price:u64, coinType:String, clock:&Clock, type:String, nft:Nft, ctx:&mut TxContext): OnSale {
        let now = clock::timestamp_ms(clock);
        let bags = bag::new(ctx);
        let nftType = string::from_ascii(*type_name::borrow_string(&type_name::get<Nft>()));
        let addr = object::id_address(&nft);
        bag::add(&mut bags, 0, nft);
        OnSale {
            id: object::new(ctx),
            name: name,
            price: price,
            num: 1,
            coinType: coinType,
            owner:tx_context::sender(ctx),
            metaId:metaId,
            type: type,
            onsale_time: now,
            bag: bags,
            nftType: nftType,
            nft_addr: addr
        }
    }

    fun new_sale(metaId:u64, name:String, num:u64, price:u64, coinType:String, clock:&Clock, type:String, ctx:&mut TxContext): OnSale {
        let now = clock::timestamp_ms(clock);
        OnSale {
            id: object::new(ctx),
            name: name,
            price: price,
            coinType: coinType,
            num: num,
            owner:tx_context::sender(ctx),
            metaId: metaId,
            type: type,
            onsale_time: now,
            bag: bag::new(ctx),
            nftType: utf8(b""),
            nft_addr: @empty_addr
        }
    }

    public entry fun get_game_sales(global: &MarketGlobal, _clock:&Clock) : string::String {
        let table = &global.game_sales;
        if (linked_table::is_empty(table)) {
            return utf8(b"none")
        };
        let vec_out:vector<u8> = vector::empty<u8>();
        let key = linked_table::front(table);
        let key_value = *option::borrow(key);
        let sales_vec = linked_table::borrow(table, key_value);
        vector::append(&mut vec_out, print_onsale_vector(sales_vec));
        let next = linked_table::next(table, *option::borrow(key));
        while (option::is_some(next)) {
            key_value = *option::borrow(next);
            sales_vec = linked_table::borrow(table, key_value);
            vector::append(&mut vec_out, print_onsale_vector(sales_vec));
            next = linked_table::next(table, key_value);
        };
        utf8(vec_out)
    }

    fun print_onsale_vector(my_sales:&vector<OnSale>): vector<u8> {
        // ;
        let byte_semi = ascii::byte(ascii::char(59));
        // ,
        let byte_comma = ascii::byte(ascii::char(44));
        let vec_out:vector<u8> = *string::bytes(&string::utf8(b""));
        let (i, len) = (0u64, vector::length(my_sales));
        while (i < len) {
            let onSale:&OnSale = vector::borrow(my_sales, i);
            let onsale_id_str = address::to_string(object::uid_to_address(&onSale.id));
            vector::append(&mut vec_out, *string::bytes(&string::utf8(b"0x")));
            vector::append(&mut vec_out, *string::bytes(&onsale_id_str));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, *string::bytes(&onSale.name));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, *string::bytes(&onSale.nftType));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, numbers_to_ascii_vector(onSale.num));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, numbers_to_ascii_vector(onSale.price));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, *string::bytes(&onSale.coinType));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, *string::bytes(&onSale.type));
            vector::push_back(&mut vec_out, byte_comma);
            let owner_addr_str = address::to_string(onSale.owner);
            vector::append(&mut vec_out, *string::bytes(&string::utf8(b"0x")));
            vector::append(&mut vec_out, *string::bytes(&owner_addr_str));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, numbers_to_ascii_vector(onSale.metaId));
            vector::push_back(&mut vec_out, byte_comma);
            let nft_addr = address::to_string(onSale.nft_addr);
            vector::append(&mut vec_out, *string::bytes(&nft_addr));
            vector::push_back(&mut vec_out, byte_comma);
            vector::append(&mut vec_out, numbers_to_ascii_vector(onSale.onsale_time));
            vector::push_back(&mut vec_out, byte_semi);
            i = i + 1
        };
        vec_out
    }

    public entry fun unlist_game_item (
        global:&mut MarketGlobal, 
        meta: &mut MetaIdentity, 
        name: String,
        num: u64,
        price: u64,
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let metaId = metaIdentity::getMetaId(meta);
        assert!(linked_table::contains(&global.game_sales, metaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, metaId);
        let (i, len) = (0u64, vector::length(his_sales));
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price == price) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:_, num:_, price:_, coinType:_, owner:owner, metaId:metaId, type:_, onsale_time:onsale_time, bag:items, nft_addr:_, nftType:_} = sale;
                let time_dif = clock::timestamp_ms(clock) - onsale_time;
                let days = time_dif / DAY_IN_MS;
                if (days < 10) {
                    assert!(owner == tx_context::sender(ctx), ERR_NOT_OWNER);  
                };
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, metaId);
                    vector::destroy_empty(vec);
                };
                tree_of_life::fill_items(meta, name, num);
                break
            };
            i = i + 1
        };
    }

    #[lint_allow(self_transfer)]
    public entry fun unlist_nft_item<T:key+store> (
        global:&mut MarketGlobal, 
        meta: &mut MetaIdentity,
        name: String,
        num: u64,
        price: u64,
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let metaId = metaIdentity::getMetaId(meta);
        assert!(linked_table::contains(&global.game_sales, metaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, metaId);
        let (i, len) = (0u64, vector::length(his_sales)); 
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price == price) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:_, num:_, price:_, coinType:_, owner:owner, metaId:_, type:_, onsale_time:onsale_time, bag:items, nft_addr:_, nftType:_} = sale;
                let time_dif = clock::timestamp_ms(clock) - onsale_time;
                let days = time_dif / DAY_IN_MS;
                if (days < 10) {
                    assert!(owner == tx_context::sender(ctx), ERR_NOT_OWNER);  
                };
                if (bag::length(&items) > 0) {
                    let nft = bag::remove<u64, T>(&mut items, 0);
                    transfer::public_transfer(nft, tx_context::sender(ctx));
                };
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, metaId);
                    vector::destroy_empty(vec);
                };
                break
            };
            i = i + 1
        };
    }

    #[lint_allow(self_transfer)]
    public entry fun purchase_nft_item_sui<Nft: key + store> (
        global:&mut MarketGlobal, 
        markertRightGlobal: &mut market_right::MarketRightGlobal,
        meta: &mut MetaIdentity,
        ownerMetaId: u64,
        name: String,
        num: u64,
        payment:vector<Coin<SUI>>,
        clock: &Clock, 
        ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(ownerMetaId != metaIdentity::getMetaId(meta), ERR_CAN_NOT_BUY_YOUR_ITEM);
        let now = clock::timestamp_ms(clock);   
        let merged_coins = merge_coins<SUI>(payment, ctx);
        assert!(linked_table::contains(&global.game_sales, ownerMetaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, ownerMetaId);
        let (i, len) = (0u64, vector::length(his_sales));
        let value = value(&merged_coins);
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price <= value) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:name, num:num, price, coinType:coinType, owner:owner, metaId:_, type:type, onsale_time:_, bag:items, nft_addr:_, nftType:_} = sale;
                event::emit(
                    TransactionRecord {
                        seller:owner,
                        buyer:tx_context::sender(ctx),
                        name:name,
                        num:num,
                        price:price,
                        price_gas:price/1000,
                        type:type,
                        coinType:coinType,
                        time:now
                    }
                );
                if (bag::length(&items) > 0) {
                    let nft = bag::remove<u64, Nft>(&mut items, 0);
                    transfer::public_transfer(nft, tx_context::sender(ctx));
                };
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, ownerMetaId);
                    vector::destroy_empty(vec);
                };
                let payment = coin::split(&mut merged_coins, price * 999 / 1000, ctx);

                let market_gas = coin::split(&mut merged_coins, price / 1000, ctx);
                let fee = coin::into_balance(market_gas);
                market_right::into_gas_pool_nft_SUI(markertRightGlobal, fee);
                transfer::public_transfer(payment, owner);
                break
            };
            i = i + 1
        };
        value = value(&merged_coins);
        if (value > 0) {
            transfer::public_transfer(merged_coins, tx_context::sender(ctx))
        } else {
            destroy_zero(merged_coins);
        };
    }

    
    #[lint_allow(self_transfer)]
    public entry fun purchase_nft_item_shui<Nft: key + store> (
        global:&mut MarketGlobal, 
        markertRightGlobal: &mut market_right::MarketRightGlobal,
        meta: &mut MetaIdentity,
        ownerMetaId: u64,
        name: String,
        num: u64,
        payment:vector<Coin<SHUI>>,
        clock: &Clock, 
        ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(ownerMetaId != metaIdentity::getMetaId(meta), ERR_CAN_NOT_BUY_YOUR_ITEM);
        let now = clock::timestamp_ms(clock);   
        let merged_coins = merge_coins<SHUI>(payment, ctx);
        assert!(linked_table::contains(&global.game_sales, ownerMetaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, ownerMetaId);
        let (i, len) = (0u64, vector::length(his_sales));
        let value = value(&merged_coins);
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price <= value) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:name, num:num, price, coinType:coinType, owner:owner, metaId:_, type:type, onsale_time:_, bag:items, nft_addr:_, nftType:_} = sale;
                event::emit(
                    TransactionRecord {
                        seller:owner,
                        buyer:tx_context::sender(ctx),
                        name:name,
                        num:num,
                        price:price,
                        price_gas:price/1000,
                        type:type,
                        coinType:coinType,
                        time:now
                    }
                );
                if (bag::length(&items) > 0) {
                    let nft = bag::remove<u64, Nft>(&mut items, 0);
                    transfer::public_transfer(nft, tx_context::sender(ctx));
                };
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, ownerMetaId);
                    vector::destroy_empty(vec);
                };
                let payment = coin::split(&mut merged_coins, price * 995 / 1000, ctx);
                let market_gas = coin::split(&mut merged_coins, price * 5 / 1000, ctx);
                let fee = coin::into_balance(market_gas);
                market_right::into_gas_pool_nft_SHUI(markertRightGlobal, fee);
                transfer::public_transfer(payment, owner);
                break
            };
            i = i + 1
        };
        value = value(&merged_coins);
        if (value > 0) {
            transfer::public_transfer(merged_coins, tx_context::sender(ctx))
        } else {
            destroy_zero(merged_coins);
        };
    }

    #[lint_allow(self_transfer)]
    public entry fun purchase_game_item_sui (
        global:&mut MarketGlobal,
        markertRightGlobal: &mut market_right::MarketRightGlobal,
        meta: &mut MetaIdentity, 
        ownerMetaId: u64,
        name: String,
        num: u64,
        payment:vector<Coin<SUI>>,
        clock: &Clock, 
        ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let merged_coins = merge_coins<SUI>(payment, ctx);
        assert!(linked_table::contains(&global.game_sales, ownerMetaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, ownerMetaId);
        let now = clock::timestamp_ms(clock); 
        let (i, len) = (0u64, vector::length(his_sales));
        let value = value(&merged_coins);
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price <= value) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:name, num:num, price, coinType:coinType, owner:owner, metaId:metaId, type:type, onsale_time:_, bag:items, nft_addr:_, nftType:_} = sale;
                event::emit(
                    TransactionRecord {
                        seller:owner,
                        buyer:tx_context::sender(ctx),
                        name:name,
                        num:num,
                        price:price,
                        price_gas: price / 1000,
                        type:type,
                        coinType:coinType,
                        time:now
                    }
                );
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, metaId);
                    vector::destroy_empty(vec);
                };
                let payment = coin::split<SUI>(&mut merged_coins, price * 999 / 1000, ctx);
                let market_gas = coin::split<SUI>(&mut merged_coins, price / 1000, ctx);
                let fee = coin::into_balance<SUI>(market_gas);
                market_right::into_gas_pool_game_SUI(markertRightGlobal, fee);
                transfer::public_transfer(payment, owner);
                tree_of_life::fill_items(meta, name, num);
                break
            };
            i = i + 1
        };
        value = value(&merged_coins);
        if (value > 0) {
            transfer::public_transfer(merged_coins, tx_context::sender(ctx))
        } else {
            destroy_zero(merged_coins);
        };
    }

    #[lint_allow(self_transfer)]
    public entry fun purchase_game_item_shui (
        global:&mut MarketGlobal,
        markertRightGlobal: &mut market_right::MarketRightGlobal,
        meta: &mut MetaIdentity, 
        ownerMetaId: u64,
        name: String,
        num: u64,
        payment:vector<Coin<SHUI>>,
        clock: &Clock, 
        ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let merged_coins = merge_coins<SHUI>(payment, ctx);
        assert!(linked_table::contains(&global.game_sales, ownerMetaId), ERR_SALES_NOT_EXIST);
        let his_sales = linked_table::borrow_mut(&mut global.game_sales, ownerMetaId);
        let now = clock::timestamp_ms(clock); 
        let (i, len) = (0u64, vector::length(his_sales));
        let value = value(&merged_coins);
        while (i < len) {
            let onSale:&OnSale = vector::borrow(his_sales, i);
            if (onSale.name == name && onSale.num == num && onSale.price <= value) {
                let sale = vector::remove(his_sales, i);
                let OnSale {id, name:name, num:num, price, coinType:coinType, owner:owner, metaId:metaId, type:type, onsale_time:_, bag:items, nft_addr:_, nftType:_} = sale;
                event::emit(
                    TransactionRecord {
                        seller:owner,
                        buyer:tx_context::sender(ctx),
                        name:name,
                        num:num,
                        price:price,
                        price_gas: price / 1000,
                        type:type,
                        coinType:coinType,
                        time:now
                    }
                );
                bag::destroy_empty(items);
                object::delete(id);
                if (vector::length(his_sales) == 0) {
                    let vec = linked_table::remove(&mut global.game_sales, metaId);
                    vector::destroy_empty(vec);
                };
                let payment = coin::split<SHUI>(&mut merged_coins, price * 999 / 1000, ctx);
                let market_gas = coin::split<SHUI>(&mut merged_coins, price / 1000, ctx);
                let fee = coin::into_balance<SHUI>(market_gas);
                market_right::into_gas_pool_game_SHUI(markertRightGlobal, fee);
                transfer::public_transfer(payment, owner);
                tree_of_life::fill_items(meta, name, num);
                break
            };
            i = i + 1
        };
        value = value(&merged_coins);
        if (value > 0) {
            transfer::public_transfer(merged_coins, tx_context::sender(ctx))
        } else {
            destroy_zero(merged_coins);
        };
    }

    public fun merge_coins<T>(
        coins: vector<Coin<T>>,
        ctx: &mut TxContext,
    ): Coin<T> {
        let len = vector::length(&coins);
        if (len > 0) {
            let base_coin = vector::pop_back(&mut coins);
            while (!vector::is_empty(&coins)) {
                coin::join(&mut base_coin, vector::pop_back(&mut coins));
            };
            vector::destroy_empty(coins);

            base_coin
        } else {
            vector::destroy_empty(coins);
            coin::zero<T>(ctx)
        }
    }

    public entry fun list_game_item (
        global: &mut MarketGlobal,
        meta: &mut MetaIdentity,
        name: String,
        price: u64,
        num: u64,
        coinType: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        tree_of_life::extract_drop_items(meta, name, num);
        let sales = &mut global.game_sales;
        let metaId = metaIdentity::getMetaId(meta);
        let type = utf8(b"gamefi");
        assert!((coinType == utf8(b"SUI") || coinType == utf8(b"SHUI")), ERR_INVALID_COIN);
        if (linked_table::contains(sales, metaId)) {
            let my_sales = linked_table::borrow_mut(sales, metaId);
            assert!(vector::length(my_sales) <= 10, ERR_EXCEED_MAX_ON_SALE_NUM);
            let new_sale = new_sale(metaId, name, num, price, coinType, clock, type, ctx);
            vector::push_back(my_sales, new_sale);
        } else {
            let new_sales = vector::empty<OnSale>();
            let new_sale = new_sale(metaId, name, num, price, coinType, clock, type, ctx);
            vector::push_back(&mut new_sales, new_sale);
            linked_table::push_back(sales, metaId, new_sales);
        };
    }

    public entry fun list_nft_item<Nft:key + store> (
        global: &mut MarketGlobal,
        meta: &mut MetaIdentity,
        name: String,
        price: u64,
        coinType: String,
        clock: &Clock,
        nft:Nft,
        ctx: &mut TxContext
    ) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let sales = &mut global.game_sales;
        let metaId = metaIdentity::getMetaId(meta);
        let type = utf8(b"nft");
        assert!((coinType == utf8(b"SUI") || coinType == utf8(b"SHUI")), ERR_INVALID_COIN);
        if (linked_table::contains(sales, metaId)) {
            let my_sales = linked_table::borrow_mut(sales, metaId);
            assert!(vector::length(my_sales) <= 10, ERR_EXCEED_MAX_ON_SALE_NUM);
            let new_sale = new_nft_sale<Nft>(metaIdentity::getMetaId(meta), name, price, coinType, clock, type, nft, ctx);
            vector::push_back(my_sales, new_sale);
        } else {
            let new_sales = vector::empty<OnSale>();
            let new_sale = new_nft_sale<Nft>(metaIdentity::getMetaId(meta), name, price, coinType, clock, type, nft, ctx);
            vector::push_back(&mut new_sales, new_sale);
            linked_table::push_back(sales, metaId, new_sales);
        };
    }

    public fun query_my_onsale(global: &MarketGlobal, metaId:u64) : String {
        let table = &global.game_sales;
        if (linked_table::is_empty(table)) {
            return utf8(b"none")
        };
        if (!linked_table::contains(table, metaId)) {
            return utf8(b"none")
        };
        let vec_out:vector<u8> = vector::empty<u8>();
        let sales_vec = linked_table::borrow(table, metaId);
        vector::append(&mut vec_out, print_onsale_vector(sales_vec));
        utf8(vec_out)
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

    #[lint_allow(self_transfer)]
    public entry fun withdraw_sui(global: &mut MarketGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SUI, amount);
        let sui = coin::from_balance(balance, ctx);
        transfer::public_transfer(sui, tx_context::sender(ctx));
    }

    #[lint_allow(self_transfer)]
    public entry fun withdraw_shui(global: &mut MarketGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }

    public fun change_owner(global:&mut MarketGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }

    public fun increment(global: &mut MarketGlobal, version: u64) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        global.version = version;
    }
}