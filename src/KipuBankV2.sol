// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*///////////////////////
        Libraries
///////////////////////*/
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*///////////////////////
        Interfaces
///////////////////////*/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * @title KipuBankV2 – Smart contract in Solidity.
 * @notice Enhanced banking system with multi-token support and price oracle.
 * @dev Evolution of KipuBank with administrative features and USD conversion.
 * @author Marcelo Walter Castellan.
 * @date 23/10/2025.
 */

contract KipuBankV2 is Ownable, Pausable, ReentrancyGuard {
    /*///////////////////////
        Types declarations.
    ///////////////////////*/
    using SafeERC20 for IERC20;
    address public constant NATIVE_TOKEN = address(0);

    /*///////////////////////
        State variables - Immutable.
    ///////////////////////*/
    ///@notice immutable variable to store priceFeed address.
    AggregatorV3Interface private immutable i_priceFeed;

    ///@notice immutable variable to store maximum deposit limit in USD.
    uint256 private immutable i_bankCapUSD;

    ///@notice immutable variable to store maximum withdrawal limit per transaction in USD.
    uint256 private immutable i_withdrawalLimitUSD;

    /*///////////////////////
        State variables - Storage.
    ////////////////////////*/
    ///@notice variable to store total number of deposits.
    uint256 private s_totalDeposits;

    ///@notice variable to store total number of withdrawals.
    uint256 private s_totalWithdrawals;

    /*///////////////////////
        Mappings
    ////////////////////////*/
    ///@notice sender's balance in the given token.
    mapping(address => mapping(address => uint256)) private s_userBalances;

    ///@notice whether the token is supported.
    mapping(address => bool) private s_isTokenSupported;

    /*///////////////////////
        Events
    ////////////////////////*/
    ///@notice deposit event.
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    ///@notice withdrawal event.
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    ///@notice token supported event.
    event TokenSupported(address indexed token);
    ///@notice token removed event.
    event TokenRemoved(address indexed token);

    /*///////////////////////
        Custom errors
    ////////////////////////*/
    ///@notice error thrown when amount = 0.
    error KipuBank__ZeroAmount();

    ///@notice error thrown for insufficient balance.
    error KipuBank__InsufficientBalance();

    ///@notice error thrown when bank cap is exceeded.
    error KipuBank__BankCapExceeded(
        uint256 current,
        uint256 attempted,
        uint256 cap
    );

    ///@notice error thrown when withdrawal limit is exceeded.
    error KipuBank__WithdrawalLimitExceeded(uint256 amount, uint256 limit);

    ///@notice error thrown when transfer fails.
    error KipuBank__TransferFailed();

    ///@notice error thrown when oracle returns invalid price.
    error KipuBank__OracleFailed(string reason);

    ///@notice error thrown when token is not supported.
    error KipuBank__TokenNotSupported(address token);

    ///@notice error thrown when native token should be used for deposit.
    error KipuBank__UseDepositNative();

    ///@notice error thrown when native token should be used for withdrawal.
    error KipuBank__UseWithdrawNative();

    ///@notice error thrown when trying to remove native token support.
    error KipuBank__CannotRemoveNativeToken();

    /*///////////////////////
        Modifiers
    ////////////////////////*/
    ///@notice validates that amount is greater than zero.
    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert KipuBank__ZeroAmount();
        _;
    }
    ///@notice validates that token is supported.
    modifier tokenSupported(address _token) {
        if (!s_isTokenSupported[_token])
            revert KipuBank__TokenNotSupported(_token);
        _;
    }

    /*///////////////////////
        Functions
    ////////////////////////*/
    /**
     * @notice Initializes the KipuBankV2 contract with deposit and withdrawal limits and the oracle address.
     * @dev Marks the native token as supported by default.
     * @param _bankCapUSD Maximum deposit limit in USD.
     * @param _withdrawalLimitUSD Maximum withdrawal limit per transaction in USD.
     * @param _priceFeedAddress Address of the Chainlink oracle contract.
     */

    constructor(
        uint256 _bankCapUSD,
        uint256 _withdrawalLimitUSD,
        address _priceFeedAddress
    ) Ownable(msg.sender) {
        i_bankCapUSD = _bankCapUSD;
        i_withdrawalLimitUSD = _withdrawalLimitUSD;
        i_priceFeed = AggregatorV3Interface(_priceFeedAddress);
        s_isTokenSupported[NATIVE_TOKEN] = true;
    }

    /*///////////////////////
        External functions
    ////////////////////////*/
    /**
     * @notice Deposits native ETH into the bank.
     * @dev Checks deposit limits and token support before accepting funds.
     * @custom:requirements The contract must be active (not paused) and the native token must be supported.
     * @custom:events Emits a {Deposit} event with deposit details.
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

        if (currentBankValueUSD + depositValueUSD > i_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                i_bankCapUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] += msg.value;
        s_totalDeposits++;

        emit Deposit(msg.sender, NATIVE_TOKEN, msg.value, depositValueUSD);
    }

    /**
     * @notice Deposits ERC-20 tokens into the bank.
     * @dev Uses SafeERC20 for secure transfers. Calculates the actual received amount to prevent rounding errors.
     * @param _tokenAddress Address of the ERC-20 token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @custom:requirements Contract must be active and token must be supported.
     * @custom:events Emits a {Deposit} event with deposit details.
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
     * @notice Withdraws native ETH from the bank.
     * @dev Checks the user's balance and withdrawal limit before transferring.
     * @param _amount Amount of ETH to withdraw.
     * @custom:requirements User must have sufficient balance and the withdrawal must not exceed the USD limit.
     * @custom:events Emits a {Withdrawal} event with withdrawal details.
     */
    function withdrawNative(
        uint256 _amount
    ) external nonReentrant validAmount(_amount) {
        if (s_userBalances[msg.sender][NATIVE_TOKEN] < _amount) {
            revert KipuBank__InsufficientBalance();
        }

        uint256 withdrawValueUSD = _getUSDValue(NATIVE_TOKEN, _amount);
        if (withdrawValueUSD > i_withdrawalLimitUSD) {
            revert KipuBank__WithdrawalLimitExceeded(
                withdrawValueUSD,
                i_withdrawalLimitUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] -= _amount;
        s_totalWithdrawals++;

        _transferNative(msg.sender, _amount);

        emit Withdrawal(msg.sender, NATIVE_TOKEN, _amount, withdrawValueUSD);
    }

    /**
     * @notice Withdraws ERC-20 tokens from the bank.
     * @dev Checks the user's balance before transferring.
     * @param _tokenAddress Address of the ERC-20 token to withdraw.
     * @param _amount Amount of tokens to withdraw.
     * @custom:requirements User must have sufficient balance in the specified token.
     * @custom:events Emits a {Withdrawal} event with withdrawal details.
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
     * @notice Adds support for a new ERC-20 token.
     * @dev Only the contract owner can execute this function.
     * @param _tokenAddress Address of the token to enable.
     * @custom:events Emits a {TokenSupported} event when the token is enabled.
     */
    function supportNewToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseDepositNative();
        }
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }

    /**
     * @notice Removes support for an ERC-20 token.
     * @dev The native token cannot be removed.
     * @param _tokenAddress Address of the token to disable.
     * @custom:events Emits a {TokenRemoved} event when the token is disabled.
     */
    function removeTokenSupport(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__CannotRemoveNativeToken();
        }
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }

    /**
     * @notice Pauses all bank operations.
     * @dev Only the contract owner can pause the contract.
     */
    function pauseBank() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes all bank operations.
     * @dev Only the contract owner can resume the contract.
     */
    function unpauseBank() external onlyOwner {
        _unpause();
    }

    /*///////////////////////
        View functions
    ////////////////////////*/
    /**
     * @notice Returns the balance of a user for a specific token.
     * @param _user Address of the user.
     * @param _token Address of the token.
     * @return User's balance in the specified token.
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
     * @notice Returns the maximum deposit limit in USD.
     * @return Current deposit limit in USD.
     */
    function getBankCapUSD() external view returns (uint256) {
        return i_bankCapUSD;
    }

    /**
     * @notice Returns the maximum withdrawal limit per transaction in USD.
     * @return Current limit in USD.
     */
    function getWithdrawalLimitUSD() external view returns (uint256) {
        return i_withdrawalLimitUSD;
    }

    /**
     * @notice Returns the address of the price oracle contract.
     * @return Address of the Chainlink oracle.
     */
    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }

    /**
     * @notice Checks whether a token is supported by the bank.
     * @param _token Address of the token.
     * @return true if supported, false otherwise.
     */
    function isTokenSupported(address _token) external view returns (bool) {
        return s_isTokenSupported[_token];
    }

    /**
     * @notice Returns bank statistics.
     * @return totalDeposits Total number of deposits.
     * @return totalWithdrawals Total number of withdrawals.
     */
    function getBankStats()
        external
        view
        returns (uint256 totalDeposits, uint256 totalWithdrawals)
    {
        return (s_totalDeposits, s_totalWithdrawals);
    }
    /**
     * @notice Returns the current ETH price from the oracle.
     * @dev Requires the price to be greater than zero.
     * @return ETH price in USD with 8 decimals.
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
     * @notice Calculates the USD value of a given ETH amount.
     * @dev Applies only to the native token.
     * @param _tokenAddress Address of the token (must be ETH).
     * @param _amount Amount in wei.
     * @return valueUSD Value in USD.
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
     * @notice Calculates the total USD value of native funds held in the contract.
     * @return Total value in USD.
     */
    function _getTotalNativeValueUSD() private view returns (uint256) {
        uint256 totalNative = address(this).balance;
        return _getUSDValue(NATIVE_TOKEN, totalNative);
    }

    /**
     * @notice Transfers native ETH to a specified address.
     * @param _to Recipient address.
     * @param _amount Amount in wei.
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

        if (currentBankValueUSD + depositValueUSD > i_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                i_bankCapUSD
            );
        }

        s_userBalances[msg.sender][NATIVE_TOKEN] += msg.value;
        s_totalDeposits++;

        emit Deposit(msg.sender, NATIVE_TOKEN, msg.value, depositValueUSD);
    }
}
