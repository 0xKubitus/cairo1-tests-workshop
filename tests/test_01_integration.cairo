// HOMEWORK Part 2: Integration Testing

use starknet::ContractAddress;
use starknet::contract_address_const; // library that allows us to initiate a dummy contract address that's useful for testing purposes

// The two below imports are required in order to be able to produce a u256 from a felt 
use integer::u256;
use integer::u256_from_felt252;

// Here, we have to import the contract "ERC20" located inside the ERC20.cairo file in "test_demo" which is the name we have attributed to the src folder in 'cairo_project.toml'
use test_demo::ERC20::ERC20; 

// We also need to import the below library to set a specific address as the caller address (useful for testing purposes)
use starknet::testing::set_caller_address;

fn setup() -> (ContractAddress, u256) {
    let name: felt252 = 'Basecamp_04';
    let symbol: felt252 = 'BSC04';
    let decimals: u8 = 18_u8;
    let initial_supply: u256 = u256_from_felt252(2000);
    let account: ContractAddress = contract_address_const::<1>();

    set_caller_address(account);

    ERC20::constructor(name, symbol, decimals, initial_supply, account);

    return (account, initial_supply);
}

#[test]
#[available_gas(2000000)]
fn test_transfer(){
    let (sender, supply) = setup(); // this declares the result from setup() function as two variables, namely "sender" and "account" 

    let recipient: ContractAddress = contract_address_const::<2>(); // make sure to create a second dummy account address here
    
    let amount: u256 = u256_from_felt252(100);
    let balance_recipient = ERC20::balance_of(recipient);
    let sender_balance = ERC20::balance_of(sender);
    let total_supply_balance = ERC20::get_total_supply();
    
    ERC20::transfer(recipient, amount);

    // STEP 1: Verify that the amount of 100 has been transferred to the recipient account
    assert(ERC20::balance_of(recipient) == balance_recipient + amount, 'ERC20:WRONG BALANCE RECIPIENT');

    // STEP 2: Verify that the balance of the sender decreases by the same amount
    assert(ERC20::balance_of(sender) == sender_balance - amount, 'ERC20:WRONG SENDER BALANCE');

    // STEP 3: Verify that the total_supply value remains the same as when it was initialized
    assert(ERC20::get_total_supply() == total_supply_balance, 'ERC20:WRONG TOTAL SUPPLY');
}