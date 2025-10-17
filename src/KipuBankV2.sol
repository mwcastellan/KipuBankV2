// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBankV2
 * @notice Sistema bancario mejorado con soporte multi-token y oracle de precios
 * @dev Evolución de KipuBank con funcionalidades administrativas y conversión a USD
 */
contract KipuBankV2 is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Type declarations
    address public constant NATIVE_TOKEN = address(0);

    // State variables - Immutable
    AggregatorV3Interface private immutable i_priceFeed;

    // State variables - Storage
    uint256 private s_bankCapUSD;
    uint256 private s_withdrawalLimitUSD;
    uint256 private s_totalDeposits;
    uint256 private s_totalWithdrawals;

    // Mappings
    mapping(address => mapping(address => uint256)) private s_userBalances;
    mapping(address => bool) private s_isTokenSupported;

    // Events
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

    // Custom errors
    error KipuBank__ZeroAmount();
    error KipuBank__InsufficientBalance();
    error KipuBank__BankCapExceeded(uint256 current, uint256 attempted, uint256 cap);
    error KipuBank__WithdrawalLimitExceeded(uint256 amount, uint256 limit);
    error KipuBank__TransferFailed();
    error KipuBank__OracleFailed(string reason);
    error KipuBank__TokenNotSupported(address token);
    error KipuBank__UseDepositNative();
    error KipuBank__UseWithdrawNative();
    error KipuBank__CannotRemoveNativeToken();

    // Modifiers
    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert KipuBank__ZeroAmount();
        _;
    }

    modifier tokenSupported(address _token) {
        if (!s_isTokenSupported[_token]) revert KipuBank__TokenNotSupported(_token);
        _;
    }

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

    // External functions
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
<<<<<<< HEAD
    }

    function depositToken(address _tokenAddress, uint256 _amount)
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
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 amountReceived = balanceAfter - balanceBefore;

        s_userBalances[msg.sender][_tokenAddress] += amountReceived;
        s_totalDeposits++;

        emit Deposit(msg.sender, _tokenAddress, amountReceived, 0);
    }

    function withdrawNative(uint256 _amount) 
        external 
        nonReentrant 
        validAmount(_amount)
    {
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

    function withdrawToken(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
        validAmount(_amount)
    {
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

    function supportNewToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseDepositNative();
        }
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }

    function removeTokenSupport(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__CannotRemoveNativeToken();
        }
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }

    function updateBankCap(uint256 _newBankCapUSD) external onlyOwner {
        s_bankCapUSD = _newBankCapUSD;
        emit BankCapUpdated(_newBankCapUSD);
    }

    function updateWithdrawalLimit(uint256 _newLimitUSD) external onlyOwner {
        s_withdrawalLimitUSD = _newLimitUSD;
        emit WithdrawalLimitUpdated(_newLimitUSD);
    }

    function pauseBank() external onlyOwner {
        _pause();
    }

    function unpauseBank() external onlyOwner {
        _unpause();
    }

    // View functions
    function getBalance(address _user, address _token) 
        external 
        view 
        returns (uint256) 
    {
        return s_userBalances[_user][_token];
    }

    function getMyBalance(address _token) external view returns (uint256) {
        return s_userBalances[msg.sender][_token];
    }

    function getBankCapUSD() external view returns (uint256) {
        return s_bankCapUSD;
    }

    function getWithdrawalLimitUSD() external view returns (uint256) {
        return s_withdrawalLimitUSD;
    }

    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }

    function isTokenSupported(address _token) external view returns (bool) {
        return s_isTokenSupported[_token];
    }

    function getBankStats() 
        external 
        view 
        returns (uint256 totalDeposits, uint256 totalWithdrawals) 
    {
        return (s_totalDeposits, s_totalWithdrawals);
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        
        if (price <= 0) {
            revert KipuBank__OracleFailed("Invalid oracle price");
        }

        return uint256(price);
    }

    // Private functions
    function _getUSDValue(address _tokenAddress, uint256 _amount)
        private
        view
        returns (uint256 valueUSD)
    {
        if (_amount == 0) return 0;
        if (_tokenAddress != NATIVE_TOKEN) return 0;

        uint256 ethPrice = getETHPrice();
        valueUSD = (_amount * ethPrice) / 10**18;
    }

    function _getTotalNativeValueUSD() private view returns (uint256) {
        uint256 totalNative = address(this).balance;
        return _getUSDValue(NATIVE_TOKEN, totalNative);
    }

    function _transferNative(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransferFailed();
        }
    }

    // Receive function
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
=======
>>>>>>> 034a085f4a56beef5cd3fe7c6f54014a07b358d7
    }

    function depositToken(address _tokenAddress, uint256 _amount)
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
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 amountReceived = balanceAfter - balanceBefore;

        s_userBalances[msg.sender][_tokenAddress] += amountReceived;
        s_totalDeposits++;

        emit Deposit(msg.sender, _tokenAddress, amountReceived, 0);
    }

    function withdrawNative(uint256 _amount) 
        external 
        nonReentrant 
        validAmount(_amount)
    {
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

    function withdrawToken(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
        validAmount(_amount)
    {
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

    function supportNewToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__UseDepositNative();
        }
        s_isTokenSupported[_tokenAddress] = true;
        emit TokenSupported(_tokenAddress);
    }

    function removeTokenSupport(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == NATIVE_TOKEN) {
            revert KipuBank__CannotRemoveNativeToken();
        }
        s_isTokenSupported[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress);
    }

    function updateBankCap(uint256 _newBankCapUSD) external onlyOwner {
        s_bankCapUSD = _newBankCapUSD;
        emit BankCapUpdated(_newBankCapUSD);
    }

    function updateWithdrawalLimit(uint256 _newLimitUSD) external onlyOwner {
        s_withdrawalLimitUSD = _newLimitUSD;
        emit WithdrawalLimitUpdated(_newLimitUSD);
    }

    function pauseBank() external onlyOwner {
        _pause();
    }

    function unpauseBank() external onlyOwner {
        _unpause();
    }

    // View functions
    function getBalance(address _user, address _token) 
        external 
        view 
        returns (uint256) 
    {
        return s_userBalances[_user][_token];
    }

    function getMyBalance(address _token) external view returns (uint256) {
        return s_userBalances[msg.sender][_token];
    }

    function getBankCapUSD() external view returns (uint256) {
        return s_bankCapUSD;
    }

    function getWithdrawalLimitUSD() external view returns (uint256) {
        return s_withdrawalLimitUSD;
    }

    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }

    function isTokenSupported(address _token) external view returns (bool) {
        return s_isTokenSupported[_token];
    }

    function getBankStats() 
        external 
        view 
        returns (uint256 totalDeposits, uint256 totalWithdrawals) 
    {
        return (s_totalDeposits, s_totalWithdrawals);
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        
        if (price <= 0) {
            revert KipuBank__OracleFailed("Invalid oracle price");
        }

        return uint256(price);
    }

    // Private functions
    function _getUSDValue(address _tokenAddress, uint256 _amount)
        private
        view
        returns (uint256 valueUSD)
    {
        if (_amount == 0) return 0;
        if (_tokenAddress != NATIVE_TOKEN) return 0;

        uint256 ethPrice = getETHPrice();
        valueUSD = (_amount * ethPrice) / 10**18;
    }

    function _getTotalNativeValueUSD() private view returns (uint256) {
        uint256 totalNative = address(this).balance;
        return _getUSDValue(NATIVE_TOKEN, totalNative);
    }

    function _transferNative(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransferFailed();
        }
    }

    // Receive function
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
