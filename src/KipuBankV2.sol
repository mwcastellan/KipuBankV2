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
 * @title KipuBankV2 – Contrato inteligente en Solidity.
 * @notice Sistema bancario mejorado con soporte multi-token y oracle de precios.
 * @dev Evolución de KipuBank con funcionalidades administrativas y conversión a USD.
 * @author Marcelo Walter Castellan.
 * @Date 19/10/2025.
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
    uint256 private immutable i_bankCapUSD;
    uint256 private immutable i_withdrawalLimitUSD;

    /*///////////////////////
        State variables - Storage
    ////////////////////////*/
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
        i_bankCapUSD = _bankCapUSD;
        i_withdrawalLimitUSD = _withdrawalLimitUSD;
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
        return i_bankCapUSD;
    }

    /**
     * @notice Obtiene el límite máximo de retiro por transacción en USD.
     * @return Límite actual en USD.
     */
    function getWithdrawalLimitUSD() external view returns (uint256) {
        return i_withdrawalLimitUSD;
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
