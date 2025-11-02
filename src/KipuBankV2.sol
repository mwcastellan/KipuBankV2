// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


/// @title KipuBankV2 – Smart contract in Solidity.
/// \1/// @custom-policy Paused: deposits disabled (including receive), withdrawals remain allowed.
/// @custom-policy Cap: USD cap applies to native ETH only in this version.
/// @dev Evolution of KipuBank with administrative features and USD conversion.
/// @author Marcelo Walter Castellan.
/// @date 02/11/2025.

/* //////////////////////////////////////////////////////////////////////////////////////// */
/*                     Imports                                                              */
/* //////////////////////////////////////////////////////////////////////////////////////// */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/* //////////////////////////////////////////////////////////////////////////////////////// */
/*      Libraries          */
/* //////////////////////////////////////////////////////////////////////////////////////// */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* //////////////////////////////////////////////////////////////////////////////////////// */
/*                    Interfaces                                                            */
/* //////////////////////////////////////////////////////////////////////////////////////// */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title KipuBankV2
/// @notice A simple bank-like contract that accepts native ETH and supported ERC-20 tokens,
///         tracks per-user balances per-token, and applies USD-based limits using a Chainlink price feed.
/// @dev The contract uses OpenZeppelin's Ownable, Pausable and ReentrancyGuard. Native token is represented
///      by the zero address constant `NATIVE_TOKEN`. This contract preserves the same logic as originally provided.
contract KipuBankV2 is Ownable, Pausable, ReentrancyGuard {
    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*               Types declarations                                                         */
    /* //////////////////////////////////////////////////////////////////////////////////////// */
    using SafeERC20 for IERC20;

    /// @notice Constant that represents the native token (ETH) in mappings and checks.
    /// @dev The native token is represented by the zero address.
    address public constant NATIVE_TOKEN = address(0);

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*             State variables - Immutable                                                  */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Immutable Chainlink price feed used to get ETH/USD price.
    /// @dev Set in constructor.
    AggregatorV3Interface private immutable i_priceFeed;

    /// @notice Immutable maximum deposit limit for the whole bank in USD (scale depends on feed/usage).
    /// @dev Provided at deployment and used to prevent deposits that would exceed the cap.
    uint256 private immutable i_bankCapUSD;

    /// @notice Immutable maximum withdrawal limit per transaction in USD.
    /// @dev Provided at deployment and used to restrict large single withdrawals.
    uint256 private immutable i_withdrawalLimitUSD;

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*              State variables - Storage                                                   */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Total number of deposit operations recorded.
    /// @dev Incremented on each successful deposit (native or token).
    uint256 private s_totalDeposits;

    /// @notice Total number of withdrawal operations recorded.
    /// @dev Incremented on each successful withdrawal (native or token).
    uint256 private s_totalWithdrawals;

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                      Mappings                                                            */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Mapping of user => token => balance.
    /// @dev Balances are stored per token address. For native ETH, key is `NATIVE_TOKEN`.
    mapping(address => mapping(address => uint256)) private s_userBalances;

    /// @notice Mapping that indicates whether a token address is supported by the contract.
    /// @dev The native token is marked supported in the constructor.
    mapping(address => bool) private s_isTokenSupported;

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                       Events                                                             */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Emitted when a user deposits tokens or native ETH.
    /// @param user Address of the depositor.
    /// @param token Token address deposited (NATIVE_TOKEN for native ETH).
    /// @param amount Amount deposited (wei for native).
    /// @param valueUSD USD value of the deposit at time of deposit (0 for ERC-20 deposits that lack USD conversion here).
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    /// @notice Emitted when a user withdraws tokens or native ETH.
    /// @param user Address of the withdrawer.
    /// @param token Token address withdrawn (NATIVE_TOKEN for native ETH).
    /// @param amount Amount withdrawn (wei for native).
    /// @param valueUSD USD value of the withdrawal at time of withdrawal (0 for ERC-20 withdrawals without conversion).
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 valueUSD
    );

    /// @notice Emitted when a new token is enabled as supported.
    /// @param token Token address that was enabled.
    event TokenSupported(address indexed token);

    /// @notice Emitted when a token is removed from supported list.
    /// @param token Token address that was disabled.
    event TokenRemoved(address indexed token);

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                      Custom errors                                                       */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Thrown when an operation attempts to use zero amount.
    error KipuBank__ZeroAmount();

    /// @notice Thrown when a deposit attempt uses zero amount.
    error KipuBank__ZeroAmountDeposit();

    /// @notice Thrown when a withdrawal attempt uses zero amount.
    error KipuBank__ZeroAmountWithdrawal();

    /// @notice Thrown when the user has insufficient balance for the operation.
    error KipuBank__InsufficientBalance();

    /// @notice Thrown when a deposit would cause the bank to exceed the configured bank cap in USD.
    /// @param current Current bank USD value.
    /// @param attempted USD value attempted to be added.
    /// @param cap Configured bank cap.
    error KipuBank__BankCapExceeded(
        uint256 current,
        uint256 attempted,
        uint256 cap
    );

    /// @notice Thrown when a withdrawal exceeds the per-transaction withdrawal USD limit.
    /// @param amount USD value of attempted withdrawal.
    error KipuBank__WithdrawalLimitExceeded(uint256 amount);

    /// @notice Thrown when a native token transfer fails.
    error KipuBank__TransferFailed();

    /// @notice Thrown when the Chainlink oracle returns an invalid price or the call fails.
    error KipuBank__OracleFailed();

    /// @notice Thrown when an operation uses a token that is not supported by the bank.
    /// @param token Token address that was not supported.
    error KipuBank__TokenNotSupported(address token);

    /// @notice Thrown when a user attempts to deposit an ERC-20 token using the native deposit function.
    error KipuBank__UseDepositNative();

    /// @notice Thrown when a user attempts to withdraw native ETH using the ERC-20 withdrawal function.
    error KipuBank__UseWithdrawNative();

    /// @notice Thrown when trying to remove the native token from supported tokens.
    error KipuBank__CannotRemoveNativeToken();
    /// @notice Thrown when a function is blocked due to pause state.
    error KipuBank__Paused();

    /// @notice Thrown when oracle data is stale by time threshold.
    error KipuBank__OracleStaleData();

    /// @notice Thrown when oracle answeredInRound < roundId (incomplete).
    error KipuBank__OracleStaleRound();

    /// @notice Thrown when an invalid address is provided.
    error KipuBank__InvalidAddress();

    /// @notice Thrown when trying to support an already supported token.
    error KipuBank__AlreadySupported();

    /// @notice Thrown when trying to remove/operate on a non-supported token.
    error KipuBank__NotSupported();


    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                         Modifiers                                                        */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Ensures deposit amount is non-zero.
    /// @param _amount Amount to validate.
    modifier nonZeroDeposit(uint256 _amount) {
        if (_amount == 0) revert KipuBank__ZeroAmountDeposit();
        _;
    }

    /// @notice Ensures withdrawal amount is non-zero.
    /// @param _amount Amount to validate.
    modifier nonZeroWithdrawal(uint256 _amount) {
        if (_amount == 0) revert KipuBank__ZeroAmountWithdrawal();
        _;
    }

    /// @notice Ensures the token provided is supported by the bank.
    /// @param _token Token address to check.
    modifier tokenSupported(address _token) {
        if (!s_isTokenSupported[_token])
            revert KipuBank__TokenNotSupported(_token);
        _;
    }

    /// @notice Ensures the `_user` has at least `_amount` balance in `_token`.
    /// @param _user User address.
    /// @param _token Token address.
    /// @param _amount Amount required.
    modifier onlySufficientBalance(
        address _user,
        address _token,
        uint256 _amount
    ) {
        if (s_userBalances[_user][_token] < _amount) {
            revert KipuBank__InsufficientBalance();
        }
        _;
    }

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                            Functions                                                     */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Initializes the KipuBankV2 contract with deposit and withdrawal limits and the oracle address.
    /// @dev Marks the native token as supported by default.
    /// @param _bankCapUSD Maximum deposit limit in USD.
    /// @param _withdrawalLimitUSD Maximum withdrawal limit per transaction in USD.
    /// @param _priceFeedAddress Address of the Chainlink oracle contract.
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

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                         External functions                                               */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Deposits native ETH into the bank.
    /// @dev Checks deposit limits and token support before accepting funds.
    /// @custom:requirements The contract must be active (not paused) and the native token must be supported.
    /// @custom:events Emits a {Deposit} event with deposit details.
    function depositNative()
        external
        payable
        nonReentrant
        whenNotPaused
        nonZeroDeposit(msg.value)
        tokenSupported(NATIVE_TOKEN)
    {
        address user = msg.sender;
        address token = NATIVE_TOKEN;

        uint256 depositValueUSD = _getUSDValue(token, msg.value);
        uint256 currentBankValueUSD = _getTotalNativeValueUSD();

        if (currentBankValueUSD + depositValueUSD > i_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                i_bankCapUSD
            );
        }

        unchecked {
            uint256 previousBalance = s_userBalances[user][token];
            s_userBalances[user][token] = previousBalance + msg.value;
            s_totalDeposits++;
        }

        emit Deposit(user, token, msg.value, depositValueUSD);
    }

    /// @notice Deposits ERC-20 tokens into the bank.
    /// @dev Uses SafeERC20 for secure transfers. Calculates the actual received amount to prevent rounding errors.
    /// @param _tokenAddress Address of the ERC-20 token to deposit.
    /// @param _amount Amount of tokens to deposit.
    /// @custom:requirements Contract must be active and token must be supported.
    /// @custom:events Emits a {Deposit} event with deposit details.
    function depositToken(
        address _tokenAddress,
        uint256 _amount
    )
        external
        nonReentrant
        whenNotPaused
        nonZeroDeposit(_amount)
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

        address user = msg.sender;
        address token = _tokenAddress;

        unchecked {
            uint256 previousBalance = s_userBalances[user][token];
            s_userBalances[user][token] = previousBalance + amountReceived;
            s_totalDeposits++;
        }

        emit Deposit(user, token, amountReceived, 0);
    }

    /// @notice Withdraws native ETH from the bank.
    /// @dev Checks the user's balance and withdrawal limit before transferring.
    /// @param _amount Amount of ETH to withdraw.
    /// @custom:requirements User must have sufficient balance and the withdrawal must not exceed the USD limit.
    /// @custom:events Emits a {Withdrawal} event with withdrawal details.
    function withdrawNative(
        uint256 _amount
    )
        external
        nonReentrant
        nonZeroWithdrawal(_amount)
        onlySufficientBalance(msg.sender, NATIVE_TOKEN, _amount)
    {
        address user = msg.sender;
        address token = NATIVE_TOKEN;

        uint256 withdrawValueUSD = _getUSDValue(token, _amount);
        if (withdrawValueUSD > i_withdrawalLimitUSD) {
            revert KipuBank__WithdrawalLimitExceeded(withdrawValueUSD);
        }

        unchecked {
            uint256 previousBalance = s_userBalances[user][token];
            s_userBalances[user][token] = previousBalance - _amount;
            s_totalWithdrawals++;
        }

        _transferNative(user, _amount);
        emit Withdrawal(user, token, _amount, withdrawValueUSD);
    }

    /// @notice Withdraws ERC-20 tokens from the bank.
    /// @dev Checks the user's balance before transferring.
    /// @param _tokenAddress Address of the ERC-20 token to withdraw.
    /// @param _amount Amount of tokens to withdraw.
    /// @custom:requirements User must have sufficient balance in the specified token.
    /// @custom:events Emits a {Withdrawal} event with withdrawal details.
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount
    )
        external
        nonReentrant
        nonZeroWithdrawal(_amount)
        onlySufficientBalance(msg.sender, _tokenAddress, _amount)
    {
        address user = msg.sender;

        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseWithdrawNative();
        }

        unchecked {
            uint256 previousBalance = s_userBalances[user][_tokenAddress];
            s_userBalances[user][_tokenAddress] = previousBalance - _amount;
            s_totalWithdrawals++;
        }

        IERC20(_tokenAddress).safeTransfer(user, _amount);
        emit Withdrawal(user, _tokenAddress, _amount, 0);
    }

    /// @notice Adds support for a new ERC-20 token.
    /// @dev Only the contract owner can execute this function.
    /// @param _tokenAddress Address of the token to enable.
    /// @custom:events Emits a {TokenSupported} event when the token is enabled.
    function supportNewToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) revert KipuBank__UseDepositNative();
        if (_tokenAddress == address(0)) revert KipuBank__InvalidAddress();
        if (s_isTokenSupported[_tokenAddress]) revert KipuBank__AlreadySupported();
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }

    /// @notice Removes support for an ERC-20 token.
    /// @dev The native token cannot be removed.
    /// @param _tokenAddress Address of the token to disable.
    /// @custom:events Emits a {TokenRemoved} event when the token is disabled.
    function removeTokenSupport(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) revert KipuBank__CannotRemoveNativeToken();
        if (_tokenAddress == address(0)) revert KipuBank__InvalidAddress();
        if (!s_isTokenSupported[_tokenAddress]) revert KipuBank__NotSupported();
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }

    /// @notice Pauses all bank operations.
    /// @dev Only the contract owner can pause the contract.
    function pauseBank() external onlyOwner {
        _pause();
    }

    /// @notice Resumes all bank operations.
    /// @dev Only the contract owner can resume the contract.
    function unpauseBank() external onlyOwner {
        _unpause();
    }

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                      View functions                                                      */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Returns the balance of a user for a specific token.
    /// @param _user Address of the user.
    /// @param _token Address of the token.
    /// @return User's balance in the specified token.
    function getBalance(
        address _user,
        address _token
    ) external view returns (uint256) {
        return s_userBalances[_user][_token];
    }

    /// @notice Returns the caller's balance for a specific token.
    /// @param _token Address of the token.
    /// @return Balance of the caller in the specified token.
    function getMyBalance(address _token) external view returns (uint256) {
        return s_userBalances[msg.sender][_token];
    }

    /// @notice Returns the maximum deposit limit in USD.
    /// @return Current deposit limit in USD.
    function getBankCapUSD() external view returns (uint256) {
        return i_bankCapUSD;
    }

    /// @notice Returns the maximum withdrawal limit per transaction in USD.
    /// @return Current limit in USD.
    function getWithdrawalLimitUSD() external view returns (uint256) {
        return i_withdrawalLimitUSD;
    }

    /// @notice Returns the address of the price oracle contract.
    /// @return Address of the Chainlink oracle.
    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }

    /// @notice Checks whether a token is supported by the bank.
    /// @param _token Address of the token.
    /// @return true if supported, false otherwise.
    function isTokenSupported(address _token) external view returns (bool) {
        return s_isTokenSupported[_token];
    }

    /// @notice Returns bank statistics.
    /// @return totalDeposits Total number of deposits.
    /// @return totalWithdrawals Total number of withdrawals.
    function getBankStats()
        external
        view
        returns (uint256 totalDeposits, uint256 totalWithdrawals)
    {
        return (s_totalDeposits, s_totalWithdrawals);
    }

    /// @notice Returns the current ETH price from the oracle.
    /// @dev Requires the price to be greater than zero.
    /// @return ETH price in USD with 8 decimals.
    function getETHPrice() public view returns (uint256) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = i_priceFeed.latestRoundData();
        if (answer <= 0) revert KipuBank__OracleFailed();
        if (answeredInRound < roundId) revert KipuBank__OracleStaleRound();
        // Consider Chainlink feeds stale if older than 2 hours
        if (block.timestamp - updatedAt > 2 hours) revert KipuBank__OracleStaleData();

        uint8 decimals_ = AggregatorV3Interface(i_priceFeed).decimals();
        uint256 price = uint256(answer);
        if (decimals_ < 18) {
            price = price * (10 ** (18 - decimals_));
        } else if (decimals_ > 18) {
            price = price / (10 ** (decimals_ - 18));
        }
        return price;
    }

        return uint256(price);
    }

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                         Private functions                                                */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Calculates the USD value of a given ETH amount.
    /// @dev Applies only to the native token.
    /// @param _tokenAddress Address of the token (must be ETH).
    /// @param _amount Amount in wei.
    /// @return valueUSD Value in USD.
    function _getUSDValue(
        address _tokenAddress,
        uint256 _amount
    ) private view returns (uint256 valueUSD) {
        if (_amount == 0) return 0;
        if (_tokenAddress != NATIVE_TOKEN) return 0;

        uint256 ethPrice18 = getETHPrice(); // normalized to 18 decimals
        // _amount is wei (18 decimals) => (wei * price) / 1e18 == USD with 18 decimals
        return (_amount * ethPrice18) / 1e18;
    }

    /// @notice Calculates the total USD value of native funds held in the contract.
    /// @return Total value in USD.
    function _getTotalNativeValueUSD() private view returns (uint256) {
        uint256 totalNative = address(this).balance;
        return _getUSDValue(NATIVE_TOKEN, totalNative);
    }

    /// @notice Transfers native ETH to a specified address.
    /// @param _to Recipient address.
    /// @param _amount Amount in wei.
    function _transferNative(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransferFailed();
        }
    }

    /* //////////////////////////////////////////////////////////////////////////////////////// */
    /*                       Receive function                                                   */
    /* //////////////////////////////////////////////////////////////////////////////////////// */

    /// @notice Fallback receive function that accepts direct native token (ETH) deposits.
    /// @dev Automatically credits the sender's balance with the sent amount of native token.
    receive() external payable {
        if (paused()) revert KipuBank__Paused();
        address user = msg.sender;
        address token = NATIVE_TOKEN;

        if (msg.value == 0) revert KipuBank__ZeroAmount();
        if (!s_isTokenSupported[token]) {
            revert KipuBank__TokenNotSupported(token);
        }

        uint256 depositValueUSD = _getUSDValue(token, msg.value);
        uint256 currentBankValueUSD = _getTotalNativeValueUSD();

        if (currentBankValueUSD + depositValueUSD > i_bankCapUSD) {
            revert KipuBank__BankCapExceeded(
                currentBankValueUSD,
                depositValueUSD,
                i_bankCapUSD
            );
        }

        unchecked {
            uint256 previousBalance = s_userBalances[user][token];
            s_userBalances[user][token] = previousBalance + msg.value;
            s_totalDeposits++;
        }

        emit Deposit(user, token, msg.value, depositValueUSD);
    }
}
