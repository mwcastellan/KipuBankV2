// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

pragma solidity >=0.4.16;


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

pragma solidity >=0.4.16;


// File: @openzeppelin/contracts/interfaces/IERC1363.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

pragma solidity >=0.6.2;



/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: KipuBankV2.sol


pragma solidity ^0.8.30;

/*///////////////////////
        Imports
///////////////////////*/


/*///////////////////////
        Libraries
///////////////////////*/




/*///////////////////////
        Interfaces
///////////////////////*/



/*
 * @title KipuBankV2 – Contrato inteligente en Solidity.
 * @notice Sistema bancario mejorado con soporte multi-token y oracle de precios.
 * @dev Evolución de KipuBank con funcionalidades administrativas y conversión a USD.
 * @author Marcelo Walter Castellan.
 * @Date 18/10/2025.
 */

contract KipuBankV2 is Ownable, Pausable, ReentrancyGuard {
    /*///////////////////////
        Types declarations
    ///////////////////////*/
    using SafeERC20 for IERC20;
    address public constant NATIVE_TOKEN = address(0);

    /*///////////////////////
        State variables - Immutable
    ///////////////////////*/
    AggregatorV3Interface private immutable i_priceFeed;

    /*///////////////////////
        State variables - Storage
    ////////////////////////*/
    uint256 private s_bankCapUSD;
    uint256 private s_withdrawalLimitUSD;
    uint256 private s_totalDeposits;
    uint256 private s_totalWithdrawals;

    /*///////////////////////
        Mappings
    ////////////////////////*/
    mapping(address => mapping(address => uint256)) private s_userBalances;
    mapping(address => bool) private s_isTokenSupported;

    /*///////////////////////
        Events
    ////////////////////////*/
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    event TokenSupported(address indexed token);
    event TokenRemoved(address indexed token);
    event BankCapUpdated(uint256 newCap);
    event WithdrawalLimitUpdated(uint256 newLimit);

    /*///////////////////////
        Custom errors
    ////////////////////////*/
    error KipuBank__ZeroAmount();
    error KipuBank__InsufficientBalance();
    error KipuBank__BankCapExceeded(
        uint256 current,
        uint256 attempted,
        uint256 cap
    );
    error KipuBank__WithdrawalLimitExceeded(uint256 amount, uint256 limit);
    error KipuBank__TransferFailed();
    error KipuBank__OracleFailed(string reason);
    error KipuBank__TokenNotSupported(address token);
    error KipuBank__UseDepositNative();
    error KipuBank__UseWithdrawNative();
    error KipuBank__CannotRemoveNativeToken();

    /*///////////////////////
        Modifiers
    ////////////////////////*/
    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert KipuBank__ZeroAmount();
        _;
    }

    modifier tokenSupported(address _token) {
        if (!s_isTokenSupported[_token])
            revert KipuBank__TokenNotSupported(_token);
        _;
    }

    /*///////////////////////
        Functions
    ////////////////////////*/
    /**
     * @notice Inicializa el contrato KipuBankV2 con límites y dirección del oráculo.
     * @dev Marca el token nativo como soportado por defecto.
     * @param _bankCapUSD Límite máximo de depósitos en USD.
     * @param _withdrawalLimitUSD Límite máximo de retiro por transacción en USD.
     * @param _priceFeedAddress Dirección del contrato del oráculo Chainlink.
     */
    constructor(
        uint256 _bankCapUSD,
        uint256 _withdrawalLimitUSD,
        address _priceFeedAddress
    ) Ownable(msg.sender) {
        s_bankCapUSD = _bankCapUSD;
        s_withdrawalLimitUSD = _withdrawalLimitUSD;
        i_priceFeed = AggregatorV3Interface(_priceFeedAddress);
        s_isTokenSupported[NATIVE_TOKEN] = true;
    }

    /*///////////////////////
        External functions
    ////////////////////////*/
    /**
     * @notice Deposita ETH nativo en el banco.
     * @dev Verifica límites de depósito y soporte de token antes de aceptar fondos.
     * Emits a {Deposit} event.
     */
    function depositNative()
        external
        payable
        nonReentrant
        whenNotPaused
        validAmount(msg.value)
        tokenSupported(NATIVE_TOKEN)
    {
        uint256 depositValueUSD = _getUSDValue(NATIVE_TOKEN, msg.value);
        uint256 currentBankValueUSD = _getTotalNativeValueUSD();

        if (currentBankValueUSD + depositValueUSD > s_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                s_bankCapUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] += msg.value;
        s_totalDeposits++;

        emit Deposit(msg.sender, NATIVE_TOKEN, msg.value, depositValueUSD);
    }

    /**
     * @notice Deposita tokens ERC-20 en el banco.
     * @dev Usa SafeERC20 para transferencias seguras. Calcula el monto recibido para evitar errores de redondeo.
     * @param _tokenAddress Dirección del token ERC-20 a depositar.
     * @param _amount Cantidad de tokens a depositar.
     * Emits a {Deposit} event.
     */
    function depositToken(
        address _tokenAddress,
        uint256 _amount
    )
        external
        nonReentrant
        whenNotPaused
        validAmount(_amount)
        tokenSupported(_tokenAddress)
    {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseDepositNative();
        }

        uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 amountReceived = balanceAfter - balanceBefore;

        s_userBalances[msg.sender][_tokenAddress] += amountReceived;
        s_totalDeposits++;

        emit Deposit(msg.sender, _tokenAddress, amountReceived, 0);
    }

    /**
     * @notice Retira ETH nativo del banco.
     * @dev Verifica balance del usuario y límite de retiro antes de transferir.
     * @param _amount Cantidad de ETH a retirar.
     * Emits a {Withdrawal} event.
     */
    function withdrawNative(
        uint256 _amount
    ) external nonReentrant validAmount(_amount) {
        if (s_userBalances[msg.sender][NATIVE_TOKEN] < _amount) {
            revert KipuBank__InsufficientBalance();
        }

        uint256 withdrawValueUSD = _getUSDValue(NATIVE_TOKEN, _amount);
        if (withdrawValueUSD > s_withdrawalLimitUSD) {
            revert KipuBank__WithdrawalLimitExceeded(
                withdrawValueUSD,
                s_withdrawalLimitUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] -= _amount;
        s_totalWithdrawals++;

        _transferNative(msg.sender, _amount);

        emit Withdrawal(msg.sender, NATIVE_TOKEN, _amount, withdrawValueUSD);
    }

    /**
     * @notice Retira tokens ERC-20 del banco.
     * @dev Verifica balance del usuario antes de transferir.
     * @param _tokenAddress Dirección del token ERC-20 a retirar.
     * @param _amount Cantidad de tokens a retirar.
     * Emits a {Withdrawal} event.
     */
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant validAmount(_amount) {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseWithdrawNative();
        }

        if (s_userBalances[msg.sender][_tokenAddress] < _amount) {
            revert KipuBank__InsufficientBalance();
        }

        s_userBalances[msg.sender][_tokenAddress] -= _amount;
        s_totalWithdrawals++;

        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _tokenAddress, _amount, 0);
    }

    /**
     * @notice Agrega soporte para un nuevo token ERC-20.
     * @dev Solo el propietario puede ejecutar esta función.
     * @param _tokenAddress Dirección del token a habilitar.
     * Emits a {TokenSupported} event.
     */
    function supportNewToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseDepositNative();
        }
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }

    /**
     * @notice Elimina el soporte para un token ERC-20.
     * @dev No se puede eliminar el token nativo.
     * @param _tokenAddress Dirección del token a deshabilitar.
     * Emits a {TokenRemoved} event.
     */
    function removeTokenSupport(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__CannotRemoveNativeToken();
        }
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }

    /**
     * @notice Actualiza el límite máximo de depósitos en USD.
     * @param _newBankCapUSD Nuevo límite de depósito en USD.
     * Emits a {BankCapUpdated} event.
     */
    function updateBankCap(uint256 _newBankCapUSD) external onlyOwner {
        s_bankCapUSD = _newBankCapUSD;
        emit BankCapUpdated(_newBankCapUSD);
    }

    /**
     * @notice Actualiza el límite máximo de retiro por transacción en USD.
     * @param _newLimitUSD Nuevo límite de retiro en USD.
     * Emits a {WithdrawalLimitUpdated} event.
     */
    function updateWithdrawalLimit(uint256 _newLimitUSD) external onlyOwner {
        s_withdrawalLimitUSD = _newLimitUSD;
        emit WithdrawalLimitUpdated(_newLimitUSD);
    }

    /**
     * @notice Pausa todas las operaciones del banco.
     * @dev Solo el propietario puede pausar el contrato.
     */
    function pauseBank() external onlyOwner {
        _pause();
    }

    /**
     * @notice Reanuda las operaciones del banco.
     * @dev Solo el propietario puede reanudar el contrato.
     */
    function unpauseBank() external onlyOwner {
        _unpause();
    }

    /*///////////////////////
        View functions
    ////////////////////////*/
    /**
     * @notice Obtiene el balance de un usuario para un token específico.
     * @param _user Dirección del usuario.
     * @param _token Dirección del token.
     * @return Balance del usuario en ese token.
     */
    function getBalance(
        address _user,
        address _token
    ) external view returns (uint256) {
        return s_userBalances[_user][_token];
    }

    /**
     * @notice Obtiene tu propio balance para un token específico.
     * @param _token Dirección del token.
     * @return Balance del remitente en ese token.
     */
    function getMyBalance(address _token) external view returns (uint256) {
        return s_userBalances[msg.sender][_token];
    }

    /**
     * @notice Obtiene el límite máximo de depósitos en USD.
     * @return Límite actual en USD.
     */
    function getBankCapUSD() external view returns (uint256) {
        return s_bankCapUSD;
    }

    /**
     * @notice Obtiene el límite máximo de retiro por transacción en USD.
     * @return Límite actual en USD.
     */
    function getWithdrawalLimitUSD() external view returns (uint256) {
        return s_withdrawalLimitUSD;
    }

    /**
     * @notice Obtiene la dirección del contrato del oráculo de precios.
     * @return Dirección del oráculo Chainlink.
     */
    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }

    /**
     * @notice Verifica si un token está soportado por el banco.
     * @param _token Dirección del token.
     * @return true si está soportado, false si no.
     */
    function isTokenSupported(address _token) external view returns (bool) {
        return s_isTokenSupported[_token];
    }

    /**
     * @notice Obtiene estadísticas del banco.
     * @return totalDeposits Número total de depósitos.
     * @return totalWithdrawals Número total de retiros.
     */
    function getBankStats()
        external
        view
        returns (uint256 totalDeposits, uint256 totalWithdrawals)
    {
        return (s_totalDeposits, s_totalWithdrawals);
    }

    /**
     * @notice Obtiene el precio actual de ETH desde el oráculo.
     * @dev Requiere que el precio sea mayor a cero.
     * @return Precio de ETH en USD con 8 decimales.
     */
    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = i_priceFeed.latestRoundData();

        if (price <= 0) {
            revert KipuBank__OracleFailed("Invalid oracle price");
        }

        return uint256(price);
    }

    /*///////////////////////
        Private functions
    ////////////////////////*/
    /**
     * @notice Calcula el valor en USD de un monto de ETH.
     * @dev Solo aplica para el token nativo.
     * @param _tokenAddress Dirección del token (debe ser ETH).
     * @param _amount Monto en wei.
     * @return valueUSD Valor en USD.
     */
    function _getUSDValue(
        address _tokenAddress,
        uint256 _amount
    ) private view returns (uint256 valueUSD) {
        if (_amount == 0) return 0;
        if (_tokenAddress != NATIVE_TOKEN) return 0;

        uint256 ethPrice = getETHPrice();
        valueUSD = (_amount * ethPrice) / 10 ** 18;
    }

    /**
     * @notice Calcula el valor total en USD de los fondos nativos en el contrato.
     * @return Valor total en USD.
     */
    function _getTotalNativeValueUSD() private view returns (uint256) {
        uint256 totalNative = address(this).balance;
        return _getUSDValue(NATIVE_TOKEN, totalNative);
    }

    /**
     * @notice Transfiere ETH nativo a una dirección.
     * @param _to Dirección del destinatario.
     * @param _amount Monto en wei.
     */
    function _transferNative(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransferFailed();
        }
    }

    /*///////////////////////
        Receive function
    ////////////////////////*/
    receive() external payable {
        if (msg.value == 0) revert KipuBank__ZeroAmount();
        if (!s_isTokenSupported[NATIVE_TOKEN]) {
            revert KipuBank__TokenNotSupported(NATIVE_TOKEN);
        }

        uint256 depositValueUSD = _getUSDValue(NATIVE_TOKEN, msg.value);
        uint256 currentBankValueUSD = _getTotalNativeValueUSD();

        if (currentBankValueUSD + depositValueUSD > s_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                s_bankCapUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] += msg.value;
        s_totalDeposits++;

        emit Deposit(msg.sender, NATIVE_TOKEN, msg.value, depositValueUSD);
    }
}
