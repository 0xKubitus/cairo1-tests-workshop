#[contract]
mod ERC20 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
 
    // add the below line if you get the following error message while running: `cairo-test --starknet .` => error: Plugin diagnostic: Method `is_zero` not found on type "core::starknet::contract_address::ContractAddress".
    // (might be the case if you are using cairo version 1.0.0-alpha.7)
    use starknet::contract_address::ContractAddressZeroable; 

    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    #[constructor]
    fn constructor(
        name_: felt252,
        symbol_: felt252,
        decimals_: u8,
        initial_supply: u256,
        recipient: ContractAddress
    ) {
        name::write(name_);
        symbol::write(symbol_);
        decimals::write(decimals_);
        assert(!recipient.is_zero(), 'ERC20: mint to the 0 address');
        total_supply::write(initial_supply);
        balances::write(recipient, initial_supply);
        Transfer(contract_address_const::<0>(), recipient, initial_supply);
    }

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        balances::read(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        allowances::read((owner, spender))
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) {
        let sender = get_caller_address();
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        spend_allowance(sender, caller, amount);
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, amount);
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) + added_value);
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) - subtracted_value);
    }

    fn transfer_helper(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance = current_allowance.low == ONES_MASK
            & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(owner, spender, current_allowance - amount);
        }
    }

    fn approve_helper(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }
}

// HOMEWORK Part 1: Unit Testing

#[cfg (test)]
mod tests {

    use starknet::ContractAddress;
    use starknet::contract_address_const; // library that allows us to initiate a dummy contract address that's useful for testing purposes

    // The two below imports are required in order to be able to produce a u256 from a felt 
    use integer::u256;
    use integer::u256_from_felt252;

    use super::ERC20; // Here we're importing the module of the contract which is in the same file

    #[test]
    #[available_gas(2000000)]
    fn test_constructor() {

        let name: felt252 = 'Basecamp_04';
        let symbol: felt252 = 'BSC04';
        let decimals: u8 = 18_u8;
        let initial_supply: u256 = u256_from_felt252(2000);
        let account: ContractAddress = contract_address_const::<1>();

        // Here we are invoking the constructor function from our contract (which is called `ERC20`)
        // inside our test function in order for us to test if it returns the right data:
        ERC20::constructor(name, symbol, decimals, initial_supply, account);

        // Let's use the [view] function get_name() now and check if it returns the name we gave as input parameter:
        let res_name = ERC20::get_name();
        assert(res_name == name, 'Error => ERC20: Wrong name');
        // assert(res_name == 'anything else than Basecamp_04', 'Error => ERC20: Wrong name'); // this is a test that would fail

        // Let's use get_symbol() now to test the variable "symbol", but in a one-liner:
        assert(ERC20::get_symbol() == symbol, 'Error => ERC20: Wrong symbol');

        // Let's check if the variable "decimals" has been initialized correctly:
        assert(ERC20::get_decimals() == decimals, 'Error => ERC20: Wrong decimals');

        // Let's check if the variable "total_suply" has been initialized correctly:
        assert(ERC20::get_total_supply() == initial_supply, 'Error>ERC20: Wrong total_supply'); // ATTENTION: shortstrings are maximum 31 characters long

        // Let's check if the balance of the "account" is equal to the "initial_supply":
        let accnt_blnce = ERC20::balance_of(account);
        assert(accnt_blnce == initial_supply, 'accnt_blnce != initial_supply');
    }

}