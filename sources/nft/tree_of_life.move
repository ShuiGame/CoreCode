module MetaGame::tree_of_life {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::pay;
    use sui::coin::{Self, Coin, destroy_zero};
    use std::vector::{Self};
    use MetaGame::shui::{SHUI};
    use sui::hash;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::bcs;
    use sui::clock::{Self, Clock};
    use MetaGame::items;
    use MetaGame::mission;
    use MetaGame::metaIdentity::{Self, MetaIdentity, get_items};
    use MetaGame::shui_ticket::{Self};
    use std::string::{Self, String, utf8};
    use sui::event;
    friend MetaGame::market;

    const HOUR_IN_MS:u64 = 3_600_000;
    const AMOUNT_DECIMAL: u64 = 1_000_000_000;
    const ERR_INTERVAL_TIME_ONE_DAY:u64 = 0x001;
    const ERR_COIN_NOT_ENOUGH:u64 = 0x003;
    const ERR_INVALID_NAME:u64 = 0x004;
    const ERR_INVALID_TYPE:u64 = 0x005;
    const ERR_NO_PERMISSION:u64 = 0x006;
    const ERR_INVALID_VERSION:u64 = 0x007;
    const VERSION: u64 = 0;

    struct Tree_of_life has key, store {
        id:UID,
        name: String,
        level:u16,
        exp:u16,
    }

    struct TreeGlobal has key {
        id: UID,
        balance_SHUI: Balance<SHUI>,
        total_water_amount: u64,
        creator: address,
        water_down_last_time_records: Table<u64, u64>,
        water_down_person_exp_records: Table<u64, u64>,
        version: u64
    }

    // ====== Events ======
    // For when someone has purchased a donut.
    struct GetFruit has copy, drop {
        meta_id: u64,
        element_reward: string::String,
    }

    struct GetElement has copy, drop {
        meta_id: u64,
        element_reward: string::String,
    }

    struct FruitOpened has copy, drop {
        meta_id: u64,
        name: string::String,
        element_reward: string::String,
    }

    struct WaterElement has store, drop {
        class:string::String,
        name:string::String,
        desc:string::String
    }

    struct Fragment has store, drop {
        class:string::String,
        name:string::String,
        desc:string::String
    }

    struct Fruit has store, drop {}


    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = TreeGlobal {
            id: object::new(ctx),
            balance_SHUI: balance::zero(),
            total_water_amount: 0,
            creator: tx_context::sender(ctx),
            water_down_last_time_records: table::new<u64, u64>(ctx),
            water_down_person_exp_records: table::new<u64, u64>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        let global = TreeGlobal {
            id: object::new(ctx),
            balance_SHUI: balance::zero(),
            total_water_amount: 0,
            creator: tx_context::sender(ctx),
            water_down_last_time_records: table::new<u64, u64>(ctx),
            water_down_person_exp_records: table::new<u64, u64>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    #[lint_allow(self_transfer)]
    public entry fun mint(ctx:&mut TxContext) {
        let tree = Tree_of_life {
            id:object::new(ctx),
            name: utf8(b"LifeTree1"),
            level:1,
            exp:0
        };
        transfer::public_transfer(tree, tx_context::sender(ctx));
    }

    #[lint_allow(self_transfer)]
    public entry fun water_down(mission_global: &mut mission::MissionGlobal, global: &mut TreeGlobal, meta:&mut MetaIdentity, coins:vector<Coin<SHUI>>, clock: &Clock, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let amount = 1;
        let now = clock::timestamp_ms(clock);
        global.total_water_amount = global.total_water_amount + amount;
        if (table::contains(&global.water_down_last_time_records, metaIdentity::get_meta_id(meta))) {
            let lastWaterDownTime = table::borrow_mut(&mut global.water_down_last_time_records, metaIdentity::get_meta_id(meta));
            assert!((now - *lastWaterDownTime) > 8 * HOUR_IN_MS, ERR_INTERVAL_TIME_ONE_DAY);
            *lastWaterDownTime = now;
        } else {
            table::add(&mut global.water_down_last_time_records, metaIdentity::get_meta_id(meta), now);
        };
        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= amount * AMOUNT_DECIMAL, ERR_COIN_NOT_ENOUGH);
        let balance = coin::into_balance<SHUI>(
            coin::split<SHUI>(&mut merged_coin, amount * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SHUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, tx_context::sender(ctx))
        } else {
            destroy_zero(merged_coin)
        };

        // record the time and exp
        mission::add_process(mission_global, utf8(b"water down"), meta);
        if (table::contains(&global.water_down_person_exp_records, metaIdentity::get_meta_id(meta))) {
            let last_exp = *table::borrow(&global.water_down_person_exp_records, metaIdentity::get_meta_id(meta));
            if (last_exp == 2) {
                items::store_item(get_items(meta), string::utf8(b"LuckyBox"), Fruit{});
                let exp:&mut u64 = table::borrow_mut(&mut global.water_down_person_exp_records, metaIdentity::get_meta_id(meta));
                *exp = 0;
                event::emit(
                    GetFruit {
                        meta_id: metaIdentity::get_meta_id(meta),
                        element_reward: string::utf8(b"Fruit;"),
                    }
                );
            } else {
                let exp:&mut u64 = table::borrow_mut(&mut global.water_down_person_exp_records, metaIdentity::get_meta_id(meta));
                *exp = *exp + 1;
            }
        } else {
            table::add(&mut global.water_down_person_exp_records, metaIdentity::get_meta_id(meta), 1);
        };
    }

    public(friend) fun fill_items(meta:&mut MetaIdentity, name:string::String, num:u64) {
        let type = get_element_type_by_name(name);
        let item_type = get_item_type_by_name(name);
        if (item_type == string::utf8(b"Fragment")) {
            let array = create_fragments_by_class(num, type, name, *&get_desc_by_type(type, true));
            items::store_items<Fragment>(get_items(meta), name, array);
        } else if (item_type == string::utf8(b"Water Element")) {
            let array = create_water_elements_by_class(num, type, name, *&get_desc_by_type(type, false));
            items::store_items<WaterElement>(get_items(meta), name, array);
        } else if (item_type == string::utf8(b"LuckyBox")) {
            let array = create_fruits(num);
            items::store_items<Fruit>(get_items(meta), name, array);
        } else {
            assert!(false, ERR_INVALID_NAME);
        }
    }

    public(friend) fun extract_drop_items(meta:&mut MetaIdentity, name:string::String, num:u64) {
        let _type = get_element_type_by_name(name);
        let item_type = get_item_type_by_name(name);
        let items = get_items(meta);
        if (item_type == string::utf8(b"Fragment")) {
            let vec = items::extract_items<Fragment>(items, name, num);
            clear_vec<Fragment>(vec);
        } else if (item_type == string::utf8(b"Water Element")) {
            let vec = items::extract_items<WaterElement>(items, name, num);
            clear_vec<WaterElement>(vec);
        } else if (item_type == string::utf8(b"LuckyBox")) {
            let vec = items::extract_items<Fruit>(items, name, num);
            clear_vec<Fruit>(vec);
        } else {
            assert!(false, ERR_INVALID_NAME);
        }
    }

    fun clear_vec<T:store + drop>(vec:vector<T>) {
        let (i, len) = (0u64, vector::length(&vec));
        while (i < len) {
            // drop fragments
            vector::pop_back(&mut vec);
            i = i + 1;
        };
        vector::destroy_empty(vec);
    }

    public entry fun swap_fragment<T:store + drop>(global: &TreeGlobal, mission_global:&mut mission::MissionGlobal, meta:&mut MetaIdentity, fragment_type:string::String) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(check_class(&fragment_type), ERR_INVALID_TYPE);
        let items = get_items(meta);
        let fragment_name = string::utf8(b"Fragment ");
        string::append(&mut fragment_name, fragment_type);
        let vec:vector<T> = items::extract_items(items, fragment_name, 10);
        let (i, len) = (0u64, vector::length(&vec));
        while (i < len) {
            // drop fragments
            vector::pop_back(&mut vec);
            i = i + 1;
        };
        vector::destroy_empty(vec);
        let water_element_name = string::utf8(b"Water Element_");
        string::append(&mut water_element_name, *&fragment_type);
        items::store_item(get_items(meta), water_element_name, WaterElement {
            class:fragment_type,
            name:get_name_by_type(fragment_type, false),
            desc:get_desc_by_type(fragment_type, false)
        });
        event::emit(
            GetElement {
                meta_id: metaIdentity::get_meta_id(meta),
                element_reward: get_name_by_type(fragment_type, false),
            }
        );
        mission::add_process(mission_global, utf8(b"swap water element"), meta);
    }

    fun check_class(class: &string::String) : bool {
        let array = vector::empty<string::String>();
        vector::push_back(&mut array, string::utf8(b"Life"));
        vector::push_back(&mut array, string::utf8(b"Holy"));
        vector::push_back(&mut array, string::utf8(b"Memory"));
        vector::push_back(&mut array, string::utf8(b"Resurrect"));
        vector::push_back(&mut array, string::utf8(b"Blood"));
        vector::contains(&array, class)
    }

    fun random_ticket(ctx:&mut TxContext): string::String {
        let num = get_random_num(0, 10000, 0, ctx);
        let reward_string;
        if (num == 0) {
            reward_string = string::utf8(b"SHUI5000");
            shui_ticket::mint(5000, ctx)
        } else if (num <= 49) {
            reward_string = string::utf8(b"SHUI1000");
            shui_ticket::mint(1000, ctx)
        } else if (num <= 250) {
            reward_string = string::utf8(b"SHUI100");
            shui_ticket::mint(100, ctx)
        } else if (num <= 1700) {
            reward_string = string::utf8(b"SHUI10");
            shui_ticket::mint(10, ctx)
        } else {
            reward_string = string::utf8(b"");
        };
        reward_string
    }

    fun create_fruits(num:u64): vector<Fruit> {
        let array = vector::empty();
        let i = 0;
        while (i < num) {
            vector::push_back(&mut array, Fruit {});
            i = i + 1;
        };
        array
    }

    fun create_water_elements_by_class(loop_num:u64, type:string::String, name_str:string::String, desc_str:string::String) : vector<WaterElement> {
        assert!(check_class(&type), ERR_INVALID_TYPE);
        let array = vector::empty();
        let i = 0;
        while (i < loop_num) {
            vector::push_back(&mut array, WaterElement {
                class:type,
                name:name_str,
                desc:desc_str
            });
            i = i + 1;
        };
        array
    }

    fun create_fragments_by_class(loop_num:u64, type:string::String, name_str:string::String, desc_str:string::String) : vector<Fragment> {
        assert!(check_class(&type), ERR_INVALID_TYPE);
        let array = vector::empty();
        let i = 0;
        while (i < loop_num) {
            vector::push_back(&mut array, Fragment {
                class:type,
                name:name_str,
                desc:desc_str
            });
            i = i + 1;
        };
        array
    }

    public fun get_item_type_by_name(name:string::String):string::String {
        let frag_index = string::index_of(&name, &string::utf8(b"Fragment "));
        if (frag_index < string::length(&name)) {
            return string::utf8(b"Fragment")
        };
        let water_ele_index = string::index_of(&name, &string::utf8(b"Water Element "));
        if (water_ele_index < string::length(&name)) {
            return string::utf8(b"Water Element")
        };
        let fruit_index = string::index_of(&name, &string::utf8(b"LuckyBox"));
        if (fruit_index < string::length(&name)) {
            return string::utf8(b"LuckyBox")
        };
        return string::utf8(b"none")
    }

    public fun get_element_type_by_name(name:string::String):string::String {
        let len = string::length(&name);
        let frag_tag = string::utf8(b"Fragment ");
        let frag_index = string::index_of(&name, &frag_tag);
        if (frag_index < len) {
            return string::sub_string(&name, frag_index + string::length(&frag_tag), len)
        };
        let ele_tag = string::utf8(b"Water Element ");
        let water_ele_index = string::index_of(&name, &ele_tag);
        if (water_ele_index < len) {
            return string::sub_string(&name, water_ele_index + string::length(&ele_tag), len)
        };
        return string::utf8(b"none")
    }

    fun get_name_by_type(type:string::String, is_fragment:bool):string::String {
        let name = *&type;
        if (is_fragment) {
            string::append(&mut name, string::utf8(b" Fragment"))
        } else {
            string::append(&mut name, string::utf8(b" Water Element"))
        };
        name
    }

    fun get_desc_by_type(type:String, is_fragment:bool) : string::String {
        let desc;
        if (is_fragment) {
            if (type == string::utf8(b"Holy")) {
                desc = string::utf8(b"holy water element fragment desc");
            } else if (type == string::utf8(b"Memory")) {
                desc = string::utf8(b"memory water element fragment desc");
            } else if (type == string::utf8(b"Blood")) {
                desc = string::utf8(b"blood water element fragment desc");
            } else if (type == string::utf8(b"Resurrect")) {
                desc = string::utf8(b"resurrect water element fragment desc");
            } else if (type == string::utf8(b"Memory")) {
                desc = string::utf8(b"memory water element fragment desc");
            } else {
                desc = string::utf8(b"None");
            }
        } else {
            if (type == string::utf8(b"Holy")) {
                desc = string::utf8(b"holy water element desc");
            } else if (type == string::utf8(b"Memory")) {
                desc = string::utf8(b"memory water element fragment desc");
            } else if (type == string::utf8(b"Blood")) {
                desc = string::utf8(b"blood water element fragment desc");
            } else if (type == string::utf8(b"Resurrect")) {
                desc = string::utf8(b"resurrect water element fragment desc");
            } else if (type == string::utf8(b"Memory")) {
                desc = string::utf8(b"memory water element fragment desc");
            } else {
                desc = string::utf8(b"None");
            }
        };
        desc
    }

    fun receive_random_element(random:u64, meta:&mut MetaIdentity):string::String {
        let reward_string;
        let is_fragment = true;
        if (random == 0) {
            reward_string = string::utf8(b"Life");
            is_fragment = false;
        } else if (random <= 11) {
            reward_string = string::utf8(b"Memory");
            is_fragment = false;
        } else if (random <= 111) {
            reward_string = string::utf8(b"Blood");
            is_fragment = false;
        } else if (random <= 611) {
            reward_string = string::utf8(b"Holy");
        } else if (random <= 1611) {
            reward_string = string::utf8(b"Resurrect");  
            is_fragment = false;
        } else if (random <= 4111) {
            reward_string = string::utf8(b"Memory");
            is_fragment = false;
        } else if (random <= 9111) {
            reward_string = string::utf8(b"Life");
        } else if (random <= 14611) {
            reward_string = string::utf8(b"Blood");
        } else if (random <= 21611) {
            reward_string = string::utf8(b"Resurrect");
        } else {
            reward_string = string::utf8(b"Holy");
        };
        if (is_fragment) {
            let name = string::utf8(b"Fragment ");
            let res = string::utf8(b"Fragment ");
            string::append(&mut res, *&reward_string);
            string::append(&mut res, string::utf8(b":5"));
            string::append(&mut name, *&reward_string);
            let array = create_fragments_by_class(5, *&reward_string, *&get_name_by_type(reward_string, true), *&get_desc_by_type(reward_string, true));
            items::store_items(get_items(meta), name, array);
            res
        } else {
            let name = string::utf8(b"Water Element ");
            let res = string::utf8(b"Fragment ");
            string::append(&mut name, *&reward_string);
            string::append(&mut res, *&reward_string);
            items::store_item(get_items(meta), name, WaterElement {
                class:reward_string,
                name:get_name_by_type(reward_string, false),
                desc:get_desc_by_type(reward_string, false)
            });
            res
        }
    }

    public entry fun open_fruit(global: &TreeGlobal, meta:&mut MetaIdentity, ctx:&mut TxContext) : string::String {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let Fruit {} = items::extract_item(get_items(meta), string::utf8(b"LuckyBox"));
        let num = get_random_num(0, 30610, 0, ctx);
        let num_u8 = num % 255;
        let reword_element : string::String = receive_random_element(num, meta);
        let double_chance = get_random_num(0, 10, (num_u8 as u8), ctx);
        if (double_chance < 5) {
            let reward_element2 = receive_random_element(double_chance, meta);
            string::append(&mut reword_element, string::utf8(b";"));
            string::append(&mut reword_element, reward_element2);
        };
        let reword_ticket : string::String = random_ticket(ctx);
        string::append(&mut reword_element, string::utf8(b";"));
        string::append(&mut reword_element, reword_ticket);
        event::emit(
            FruitOpened {
                meta_id: metaIdentity::get_meta_id(meta),
                name: metaIdentity::get_meta_name(meta),
                element_reward: reword_element,
            }
        );
        reword_element
    }

    // [min, max]
    public fun get_random_num(min:u64, max:u64, seed_u:u8, ctx:&mut TxContext) :u64 {
        (min + bytes_to_u64(seed(ctx, seed_u))) % (max + 1)
    }

    fun bytes_to_u64(bytes: vector<u8>): u64 {
        let value = 0u64;
        let i = 0u64;
        while (i < 8) {
            value = value | ((*vector::borrow(&bytes, i) as u64) << ((8 * (7 - i)) as u8));
            i = i + 1;
        };
        return value
    }

    fun seed(ctx: &mut TxContext, seed_u:u8): vector<u8> {
        let ctx_bytes = bcs::to_bytes(ctx);
        let seed_vec = vector::empty();
        vector::push_back(&mut seed_vec, seed_u);
        let uid = object::new(ctx);
        let uid_bytes: vector<u8> = object::uid_to_bytes(&uid);
        object::delete(uid);
        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, ctx_bytes);

        vector::append<u8>(&mut info, seed_vec);

        vector::append<u8>(&mut info, uid_bytes);
        vector::append<u8>(&mut info, bcs::to_bytes(&tx_context::epoch_timestamp_ms(ctx)));
        let hash: vector<u8> = hash::keccak256(&info);
        hash
    }

    public fun get_water_down_person_exp(global: &TreeGlobal, meta:&MetaIdentity) :u64 {
        if (table::contains(&global.water_down_person_exp_records, metaIdentity::get_meta_id(meta))) {
            *table::borrow(&global.water_down_person_exp_records, metaIdentity::get_meta_id(meta))
        } else {
            0
        }
    }

    public fun get_water_down_left_time_mills(global: &TreeGlobal, meta:&MetaIdentity, clock: &Clock) : u64 {
        let now = clock::timestamp_ms(clock);
        let last_time = 0;
        if (table::contains(&global.water_down_last_time_records, metaIdentity::get_meta_id(meta))) {
            last_time = *table::borrow(&global.water_down_last_time_records, metaIdentity::get_meta_id(meta));
        };
        let next_time = last_time + 8 * HOUR_IN_MS;
        if (now < next_time) {
            next_time - now
        } else {
            0
        }
    }

    public fun get_total_water_down_amount(global:&TreeGlobal):u64 {
        global.total_water_amount
    }

    public fun change_owner(global:&mut TreeGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }

    public fun increment(global: &mut TreeGlobal, version: u64) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        global.version = version;
    }
}