module MetaGame::shui {
    use std::option::{Self};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string;
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::url;
    use MetaGame::race::{Self};
    use MetaGame::level::{Self};
    use MetaGame::gift::{Self};
    use MetaGame::avatar::{Self};

    #[test_only]
    use sui::test_scenario::{
        Scenario, ctx
    };

    friend MetaGame::airdrop;   
    friend MetaGame::swap;
    friend MetaGame::founder_team_reserve;
    friend MetaGame::mission;

    const SHUI_ICON_URL:vector<u8> = b"https://nftstorage.link/ipfs/bafybeieqqos2upvmmxzmauv6cf53ddegpjc5zkrvbpriz7iajamcxikv4y";
    const ERR_NO_PERMISSION:u64 = 0x004;
    const TOTAL_SUPPLY: u64 = 2_100_000_000;
    const GAME_RESERVE:u64 = 1_000_000_000;
    const AIRDROP_AMOUNT:u64 = 207_000_000;
    const WHITE_LIST_RESERVE:u64 = 240_000_000;
    const IEO_AMOUNT:u64 = 200_000_000;
    const MISSION_RESERVE:u64 = 82_000_000;
    const PUBLIC_SELL:u64 = 200_000_000;
    const GOLDEN_RESERVE:u64 = 100_000_000;
    const DAO_RESERVE:u64 = 50_000_000;
    const FOUNDER_TEAM_RESERVE:u64 = 21_000_000;

    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    struct SHUI has drop {}

    struct Global has key {
        id: UID,
        supply: u64,

        // split by balance
        balance_SUI: Balance<SUI>,
        balance_SHUI: Balance<SHUI>,
        creator: address,
    }

    struct Inscription has key {
        id:UID,
        name: string::String,
        gender: string::String,
        avatar: avatar::Avatar,
        race: race::Race,
        level: level::Level,
        gift: gift::Gift,
    }

    fun init(witness: SHUI, ctx: &mut TxContext) {
        let (adminCap, metadata) = coin::create_currency(witness, 
            9,
            b"SHUI",
            b"SHUI",
            b"SHUI token",
            option::some(url::new_unsafe_from_bytes(SHUI_ICON_URL)),
            ctx);
        transfer::public_freeze_object(metadata);
        let global = Global {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            supply: TOTAL_SUPPLY,
            balance_SUI: balance::zero(),
            balance_SHUI: balance::zero(),
        };
        let total_shui = mint(&mut adminCap, TOTAL_SUPPLY * AMOUNT_DECIMAL, ctx);
        transfer::public_transfer(adminCap, tx_context::sender(ctx));
        let balance = coin::into_balance<SHUI>(
            total_shui
        );
        balance::join(&mut global.balance_SHUI, balance);

        // transfer ther reserve shui to dao and foundation account;
        transfer_to_reserve(&mut global, @manager, GAME_RESERVE * AMOUNT_DECIMAL, ctx);
        transfer_to_reserve(&mut global, @manager, DAO_RESERVE * AMOUNT_DECIMAL, ctx);
        transfer::share_object(global);
    }

    #[test_only]
    public fun init_for_test(scenario: &mut Scenario) {
        let witness = SHUI{};
        init(witness, ctx(scenario));
    }

    public fun new_empty_charactor(ctx: &mut TxContext):Inscription {
        Inscription{
            id:object::new(ctx),
            name:string::utf8(b""),
            gender: string::utf8(b""),
            avatar: avatar::none(),
            race: race::none(),
            level: level::new_level(),
            gift: gift::none(),
        }
    }

    public entry fun change_gift(charactor:&mut Inscription, gift:string::String) {
        charactor.gift = gift::new_gift(gift);
    }

    fun mint(treasuryCap:&mut TreasuryCap<SHUI>, amount:u64, ctx:&mut TxContext) : Coin<SHUI>{
        coin::mint(treasuryCap, amount, ctx)
    }

    fun transfer_to_reserve(global: &mut Global, recepient:address, amount:u64, ctx:&mut TxContext) {
        let airdrop_balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(shui, recepient);
    }

    public entry fun burn(treasury: &mut TreasuryCap<SHUI>, coin: Coin<SHUI>) {
        coin::burn(treasury, coin);
    }

    public entry fun withdraw_sui(global: &mut Global, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let airdrop_balance = balance::split(&mut global.balance_SUI, amount);
        let sui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(sui, tx_context::sender(ctx));
    }

    public entry fun withdraw_shui(global: &mut Global, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let airdrop_balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }

    public(friend) fun extract_airdrop_balance(global: &mut Global, ctx: &mut TxContext) : balance::Balance<SHUI> {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        balance::split(&mut global.balance_SHUI, (AIRDROP_AMOUNT + WHITE_LIST_RESERVE) * AMOUNT_DECIMAL)
    }

    // todo: only once call
    public(friend) fun extract_swap_balance(global: &mut Global, ctx: &mut TxContext) : balance::Balance<SHUI> {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        balance::split(&mut global.balance_SHUI, (GOLDEN_RESERVE + PUBLIC_SELL + IEO_AMOUNT) * AMOUNT_DECIMAL)
    }

    public(friend) fun extract_founder_reserve_balance(global: &mut Global, ctx: &mut TxContext) : balance::Balance<SHUI> {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        balance::split(&mut global.balance_SHUI, FOUNDER_TEAM_RESERVE * AMOUNT_DECIMAL)
    }

    public(friend) fun extract_mission_reserve_balance(global: &mut Global, ctx: &mut TxContext) : balance::Balance<SHUI> {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        balance::split(&mut global.balance_SHUI, MISSION_RESERVE * AMOUNT_DECIMAL)
    }
}