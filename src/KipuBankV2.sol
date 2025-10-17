// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/*
@title KipuBank es un banco descentralizado en Ethereum.
@author Marcelo Walter Castellan.
@Date 03/10/2025.
*/

contract KipuBank {
    // Constantes e Inmutables.
    // @notice Límite máximo de retiro por transacción
    uint256 public immutable withdrawLimit;
    // @notice Límite global de depósitos permitido en el contrato
    uint256 public immutable bankCap;

    // Constructor
    constructor(uint256 _bankCap, uint256 _withdrawLimit) {
        bankCap = _bankCap;
        withdrawLimit = _withdrawLimit;
    }

    // Mappings.
    // @notice Declaración de un mapping asociado a direcciones con balance por cada usuario (almacenado en wei).
    mapping(address => uint256) private _balances;

    // Variables de almacenamiento.
    // @notice totalDeposits es el total de depositos realizados.
    uint256 public totalDeposits;
    // @notice totalWithdrawals es el total de retiros realizados.
    uint256 public totalWithdrawals;

    // Errores personalizados.
    // @notice WithdrawalExceedsLimit error cuando el retiro se excede el límite permitido.
    error WithdrawalExceedsLimit(uint256 requested, uint256 limit);
    // @notice InsufficientBalance error cuando no hay suficiente balance para retirar.
    error InsufficientBalance(uint256 available, uint256 requested);
    // @notice DepositExceedCap error cuando el deposito excede el límite permitido del banco.
    error DepositExceedCap(
        uint256 currentTotal,
        uint256 requested,
        uint256 cap
    );
    // @notice NoBalanceToWithdraw error cuando se intenta retirar sin fondo.
    error NoBalanceToWithdraw();
    // @notice TransferFailed error cuando la transferencia falla.
    error TransferFailed();

    // Eventos.
    // @notice Cuando el usuario deposita ETh
    event Deposit(address indexed user, uint256 amountInWei);
    // @notice Cuando el usuario retira ETh
    event Withdrawal(address indexed user, uint256 amountInWei);

    // Modificador.
    // @notice Mientras el valor a depositar es mayor que cero
    modifier nonZeroValue() {
        require(msg.value > 0, "Debe depositar una cantidad mayor a cero");
        _;
    }

    // Funciones.
    /*
    @notice function deposit() El usuario deposita de ETH en su boveda personal 
    se envia por (msg.value). 
    */
    function deposit() external payable nonZeroValue {
        uint256 newTotal = address(this).balance;
        if (newTotal > bankCap) {
            // Si el nuevo balance supera al limite del banco.
            revert DepositExceedCap({
                currentTotal: newTotal - msg.value,
                // El nuevo balance del contrato.
                requested: msg.value,
                // Valor enviado por el usuario.
                cap: bankCap
            });
            // Revertamos con la palabra clave revert
            // que nos permite lanzar un error personalizado.
        }
        _balances[msg.sender] += msg.value;
        totalDeposits++;
        emit Deposit(msg.sender, msg.value);
        // Emitir event de deposito con el usuario y la cantidad en wei.
    }

    /* 
    @notice function withdraw El usuario retira ETH a su cuenta boveda 
    se envia por (amount).
    */
    function withdraw(uint256 amount) external {
        // Obtener el balance del usuario desde el mapping _balances.
        uint256 userBalance = _balances[msg.sender];
        // Verificar si el usuario no tiene fondos en su bóveda.
        if (userBalance == 0) {
            // Revierte error cuando se intenta retirar sin fondo.
            revert NoBalanceToWithdraw();
        }
        // Verificar si el monto solicitado excede el límite permitido por transacción
        if (amount > withdrawLimit) {
            // Revertir con error personalizado incluyendo lo solicitado y el límite
            revert WithdrawalExceedsLimit({
                requested: amount,
                limit: withdrawLimit
            });
        }
        // Verificar si el usuario tiene suficiente balance para retirar el monto deseado.
        if (amount > userBalance) {
            // Revertir con error personalizado indicando cuánto tiene disponible y cuánto pidió
            revert InsufficientBalance({
                available: userBalance,
                requested: amount
            });
        }
        // Ejecutar el retiro.
        executeWithdrawal(msg.sender, amount);
    }

    // @notice function executeWithdrawal Ejecuta la transferencia de ETH al usuario y actualiza el estado interno.
    function executeWithdrawal(address user, uint256 amount) private {
        // Rebaja el balance interno del usuario.
        _balances[user] -= amount;
        // Incrementar el contador total de retiros.
        totalWithdrawals++;
        // Realizar la transferencia segura de ETH al usuario usando call.
        (bool success, ) = payable(user).call{value: amount}("");
        // Verificar que la transferencia fue exitosa.
        if (!success) revert TransferFailed(); // Error personalizado.
        // Emitir evento indicando que el retiro se completó.
        emit Withdrawal(user, amount);
    }

    // @notice function getBalance Consulta el balance actual de un usuario.
    function getBalance(address user) external view returns (uint256) {
        return _balances[user]; // Devolver el balance de un usuario por medio del mapping balances.
    }

    // @notice getStats() Retorna estadísticas del banco.
    function getStats()
        external
        view
        returns (uint256 deposits, uint256 Withdrawals)
    {
        return (totalDeposits, totalWithdrawals);
    }
}
