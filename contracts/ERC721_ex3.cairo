# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.2.0 (token/erc721/ERC721_Mintable_Burnable.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.access.ownable import Ownable

struct Animal:
    member sex : felt
    member legs : felt
    member wings : felt
end

@storage_var
func animals(token_id : Uint256) -> (animal : Animal):
end

@storage_var
func last_token_id() -> (token_id : Uint256):
end

@storage_var
func is_breeder(breeder_address : felt) -> (is_breeder : felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, symbol : felt, owner : felt
):
    ERC721.initializer(name, symbol)
    Ownable.initializer(owner)
    token_id_initializer()
    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt):
    let (isApproved : felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI : felt):
    let (tokenURI : felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

@view
func get_animal_characteristics{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (sex : felt, legs : felt, wings : felt):
    let animal = animals.read(token_id)
    let animal_ptr = cast(&animal, Animal*)

    return (sex=animal_ptr.sex, legs=animal_ptr.legs, wings=animal_ptr.wings)
end

@view
func get_is_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (is_true : felt):
    let (is_true : felt) = is_breeder.read(address)
    return (is_true)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256
):
    ERC721.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
):
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(tokenId : Uint256):
    ERC721.assert_only_token_owner(tokenId)
    ERC721._burn(tokenId)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, tokenURI : felt
):
    Ownable.assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func renounceOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable.renounce_ownership()
    return ()
end

@external
func declare_animal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sex : felt, legs : felt, wings : felt
) -> (token_id : Uint256):
    alloc_locals
    assert_only_breeder()

    # Increment token id by 1
    let current_token_id : Uint256 = last_token_id.read()
    let one_as_uint256 = Uint256(1, 0)
    let (local new_token_id, _) = uint256_add(current_token_id, one_as_uint256)

    let (sender_address) = get_caller_address()

    # Mint NFT and store characteristics on-chain
    ERC721._mint(sender_address, new_token_id)
    animals.write(new_token_id, Animal(sex=sex, legs=legs, wings=wings))

    # Update and return new token id
    last_token_id.write(new_token_id)
    return (token_id=new_token_id)
end

@external
func add_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    breeder_address : felt
):
    Ownable.assert_only_owner()
    is_breeder.write(breeder_address, 1)
    return ()
end

@external
func remove_breeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    breeder_address : felt
):
    Ownable.assert_only_owner()
    is_breeder.write(breeder_address, 0)
    return ()
end

func token_id_initializer{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let zero_as_uint256 : Uint256 = Uint256(0, 0)
    last_token_id.write(zero_as_uint256)
    return ()
end

func assert_only_breeder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (sender_address) = get_caller_address()
    let (is_true) = is_breeder.read(sender_address)
    with_attr error_message("Caller is not a registered breeder"):
        assert is_true = 1
    end
    return ()
end
