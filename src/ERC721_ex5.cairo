// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_check, uint256_lt
from starkware.cairo.common.math import assert_not_zero, assert_nn, split_felt

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.ownable.library import Ownable

struct Animal {
    sex: felt,
    legs: felt,
    wings: felt,
}

@storage_var
func animals(token_id: Uint256) -> (animal: Animal) {
}

@storage_var
func last_token_id() -> (token_id: Uint256) {
}

@storage_var
func _is_breeder(account: felt) -> (is_approved: felt) {
}

@storage_var
func _dummy_token_address() -> (dummy_token_address: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt, dummy_token_address: felt
) {
    ERC721.initializer(name, symbol);
    Ownable.initializer(owner);
    token_id_initializer();
    _dummy_token_address.write(dummy_token_address);
    return ();
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI: felt) {
    let (tokenURI: felt) = ERC721.token_uri(tokenId);
    return (tokenURI,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

@view
func get_animal_characteristics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (sex: felt, legs: felt, wings: felt) {
    with_attr error_message("ERC721: token_id is not a valid Uint256") {
        uint256_check(token_id);
    }
    let animal = animals.read(token_id);
    let animal_ptr = cast(&animal, Animal*);

    return (sex=animal_ptr.sex, legs=animal_ptr.legs, wings=animal_ptr.wings);
}

@view
func is_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    is_approved: felt
) {
    with_attr error_message("ERC721: the zero address can't be a breeder") {
        assert_not_zero(account);
    }
    let (is_approved: felt) = _is_breeder.read(account);
    return (is_approved,);
}

@view
func token_of_owner_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, index: felt
) -> (token_id: Uint256) {
    with_attr error_message("ERC721: the zero address is not supported as a token holder") {
        assert_not_zero(account);
    }
    with_attr error_message("ERC721: index must be a positive integer") {
        assert_nn(index);
    }
    let (index_uint256) = felt_to_uint256(index);
    let (token_id) = ERC721Enumerable.token_of_owner_by_index(owner=account, index=index_uint256);
    return (token_id,);
}

@view
func registration_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    price: Uint256
) {
    let one_as_uint256 = Uint256(1, 0);
    return (price=one_as_uint256);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func declare_dead_animal{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256
) {
    ERC721.assert_only_token_owner(token_id);
    ERC721Enumerable._burn(token_id);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    Ownable.assert_only_owner();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func declare_animal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sex: felt, legs: felt, wings: felt
) -> (token_id: Uint256) {
    alloc_locals;
    assert_only_breeder();

    // Increment token id by 1
    let current_token_id: Uint256 = last_token_id.read();
    let one_as_uint256 = Uint256(1, 0);
    let (local new_token_id, _) = uint256_add(current_token_id, one_as_uint256);

    let (sender_address) = get_caller_address();

    // Mint NFT and store characteristics on-chain
    ERC721Enumerable._mint(sender_address, new_token_id);
    animals.write(new_token_id, Animal(sex=sex, legs=legs, wings=wings));

    // Update and return new token id
    last_token_id.write(new_token_id);
    return (token_id=new_token_id);
}

@external
func register_me_as_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    is_added: felt
) {
    let (sender_address) = get_caller_address();
    let (erc721_address) = get_contract_address();
    let (price) = registration_price();
    let (dummy_token_address) = _dummy_token_address.read();

    let (success) = IERC20.transferFrom(
        contract_address=dummy_token_address,
        sender=sender_address,
        recipient=erc721_address,
        amount=price,
    );
    with_attr error_message("ERC721: unable to charge dummy tokens") {
        assert success = 1;
    }
    _is_breeder.write(account=sender_address, value=1);
    return (is_added=1);
}

@external
func unregister_me_as_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (is_added: felt) {
    let (sender_address) = get_caller_address();
    _is_breeder.write(account=sender_address, value=0);
    return (is_added=0);
}

func token_id_initializer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    last_token_id.write(zero_as_uint256);
    return ();
}

func assert_only_breeder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let (sender_address) = get_caller_address();
    let (is_true) = _is_breeder.read(sender_address);
    with_attr error_message("ERC721: Caller is not a registered breeder") {
        assert is_true = 1;
    }
    return ();
}

func felt_to_uint256{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    felt_value: felt
) -> (uint256_value: Uint256) {
    let (high, low) = split_felt(felt_value);
    let uint256_value: Uint256 = Uint256(low, high);
    return (uint256_value,);
}
