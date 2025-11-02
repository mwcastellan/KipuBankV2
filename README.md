# 🏦 KipuBankV2 – Contrato inteligente en Solidity

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.30-363636?style=flat-square&logo=solidity)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.0-4E5EE4?style=flat-square&logo=openzeppelin)](https://openzeppelin.com/)
[![Chainlink](https://img.shields.io/badge/Chainlink-Oracle-375BD2?style=flat-square&logo=chainlink)](https://chain.link/)

## Autor: Marcelo Walter Castellan

## Fecha: 02/11/2025

---

## 📘 Descripción General

**KipuBankV2** es la evolución mejorada del contrato original **KipuBank**, incorporando soporte multi-token, integración con oráculos **Chainlink**, y un sistema administrativo completo mediante **OpenZeppelin**.  
Esta versión mantiene toda la lógica original, pero con documentación técnica más precisa y mejores prácticas para auditoría y despliegue en Etherscan.

---

## 🚀 Mejoras Incorporadas

### 1. Control de Acceso y Seguridad

- `Ownable` para control administrativo.
- `Pausable` para emergencias.
- `ReentrancyGuard` contra ataques de reentrada.
- Validación adicional en constructor: `require(_priceFeedAddress != address(0))`.

### 2. Soporte Multi-Token

- Soporte para múltiples tokens ERC-20 mediante `isTokenSupported`.
- Eventos `Deposit` y `Withdrawal` con `valueUSD = 0` para tokens (intencional).
- Uso de `SafeERC20` para compatibilidad con tokens no estándar.

### 3. Integración con Chainlink Oracle

- Límite global (`bankCapUSD`) y de retiro (`withdrawalLimitUSD`) expresados en **USD con 8 decimales**.
- Sin validación de frescura (`updatedAt` / `answeredInRound`) — se asume fuente confiable.

### 4. Claridad en Unidades

- Todos los valores en USD utilizan **8 decimales** (formato estándar de Chainlink ETH/USD).
- `_getUSDValue()` convierte ETH → USD (8 decimales).
- `_getETHFromUSD()` convierte USD (8 decimales) → wei.

### 5. Comportamiento de `receive()`

- Permite recibir ETH incluso si el contrato está pausado (por diseño).
- Documentado en NatSpec para evitar confusión operativa.

### 6. Convenciones de Código y Buenas Prácticas.

- Variables inmutables con prefijo `i_` (ejemplo: `i_priceFeed`).
- Variables de storage con prefijo `s_` (ejemplo: `s_totalDeposits`).
- Variables privadas con getters públicos para mejor encapsulación.
- Errores personalizados con prefijo del contrato (ejemplo: `KipuBank__ZeroAmount`).
- Modificadores para validaciones reutilizables.

### 7. Gestión Administrativa Mejorada.

- `supportNewToken()`: Agregar tokens a la whitelist.
- `removeTokenSupport()`: Remover tokens de la whitelist.
- `pauseBank()` / `unpauseBank()`: Control de emergencia.

### 8. Estadísticas y Eventos Mejorados.

- `Deposit`: Incluye usuario, token, cantidad y valor USD.
- `Withdrawal`: Información completa de retiros.
- `TokenSupported` / `TokenRemoved`: Cambios en whitelist.
- `BankCapUpdated` / `WithdrawalLimitUpdated`: Cambios administrativos.
  **Contadores**:
- `s_totalDeposits`: Total de operaciones de depósito.
- `s_totalWithdrawals`: Total de operaciones de retiro.

### 9. Documentación Técnica (NatSpec)

Bloque global agregado al contrato para aclaraciones generales:

```solidity
/**
 * @notice Documentation addendum (no functional changes).
 * @dev
 *  - USD amounts and prices use 8 decimals (Chainlink standard).
 *  - Bank cap and per-withdrawal limit apply only to ETH.
 *  - The `receive()` function accepts ETH even when paused.
 *  - Oracle freshness is not validated.
 *  - ERC-20 events may emit valueUSD=0 intentionally.
 */
```

---

## Estructura del Contrato.

### Orden de Organización del Código.

El contrato sigue el orden estándar recomendado:

```
1. License y Pragma
2. Imports
3. Interfaces, Libraries, Contracts
4. Type declarations (constants)
5. State variables
   - Immutable
   - Storage
6. Mappings
7. Events
8. Errors
9. Modifiers
10. Constructor
11. Receive / Fallback
12. External functions
13. Public functions
14. Internal functions
15. Private functions
16. View / Pure functions
```

### Convenciones de Nomenclatura.

- **Immutable**: Prefijo `i_` → `i_priceFeed`.
- **Storage**: Prefijo `s_` → `s_totalDeposits`.
- **Internal/Private**: Prefijo `_` → `_getUSDValue()`.
- **Constants**: MAYÚSCULAS → `NATIVE_TOKEN`.
- **Errores**: `ContractName__ErrorName` → `KipuBank__ZeroAmount`.

## Instrucciones de Despliegue.

### Prerequisitos.

1. Tener instalado Remix IDE.
2. MetaMask configurado con testnet (Sepolia recomendada).
3. ETH de testnet para gas fees.

### Dependencias.

El contrato requiere las siguientes librerías:

```
@openzeppelin/contracts/access/Ownable.sol.
@openzeppelin/contracts/security/Pausable.sol.
@openzeppelin/contracts/security/ReentrancyGuard.sol.
@openzeppelin/contracts/token/ERC20/IERC20.sol.
@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol.
@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol.
```

### Dirección del Oracle Chainlink.

**Sepolia Testnet - ETH/USD**:

```
0x694AA1769357215DE4FAC081bf1f309aDC325306
```

### Parámetros del Constructor.

```solidity
constructor(
    uint256 _bankCapUSD,           // Ejemplo: 100000000000 = $1,000 USD (8 decimales)
    uint256 _withdrawalLimitUSD,   // Ejemplo: 10000000000 = $100 USD (8 decimales)
    address _priceFeedAddress      // 0x694AA1769357215DE4FAC081bf1f309aDC325306 para Sepolia
)
```

**Nota importante sobre decimales**: Los valores USD deben tener 8 decimales (formato del oracle de Chainlink).

### Proceso de Despliegue en Remix.

1. **Abrir Remix IDE** (https://remix.ethereum.org).

2. **Crear el archivo**: `src/KipuBankV2.sol`.

3. **Compilar el contrato**:

   - Seleccionar compilador ^0.8.30.
   - Hacer clic en "Compile".

4. **Conectar MetaMask**:

   - Cambiar a Sepolia testnet.
   - Asegurar tener ETH de prueba.

5. **Deploy**:

   - Ir a "Deploy & Run Transactions".
   - Seleccionar "Injected Provider - MetaMask".
   - Ingresar parámetros del constructor:.
     ```
     _bankCapUSD: 100000000000
     _withdrawalLimitUSD: 10000000000
     _priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     ```
   - Hacer clic en "Deploy".
   - Confirmar en MetaMask.

6. **Verificar el contrato** en Sepolia Etherscan.

## Cómo Interactuar con el Contrato.

### Para Usuarios Regulares.

**Depositar ETH**:

```solidity
// Opción 1: Llamar a depositNative()
depositNative{value: 0.1 ether}();

// Opción 2: Enviar ETH directamente (vía receive)
// El contrato lo procesará automáticamente
```

**Depositar Tokens ERC-20**:

```solidity
// Paso 1: Aprobar el token
IERC20(tokenAddress).approve(kipuBankV2Address, cantidad);

// Paso 2: Depositar
depositToken(tokenAddress, cantidad);
```

**Retirar ETH**:

```solidity
withdrawNative(cantidadEnWei);
```

**Retirar Tokens**:

```solidity
withdrawToken(tokenAddress, cantidad);
```

**Consultar Balances**:

```solidity
// Mi balance de ETH
getMyBalance(address(0));  // address(0) = NATIVE_TOKEN

// Mi balance de un token
getMyBalance(tokenAddress);

// Balance de otro usuario
getBalance(usuarioAddress, tokenAddress);
```

**Ver Precio de ETH**:

```solidity
getETHPrice();  // Retorna precio con 8 decimales
```

**Ver Estadísticas**:

```solidity
getBankStats();  // Retorna (totalDeposits, totalWithdrawals)
```

### Para el Owner (Administrador)

**Agregar Token a la Whitelist**:

```solidity
supportNewToken(tokenAddress);
```

**Remover Token**:

```solidity
removeTokenSupport(tokenAddress);
```

**Pausar el Banco**:

```solidity
pauseBank();
```

**Reanudar Operaciones**:

```solidity
unpauseBank();
```

## ⚙️ Decisiones de Diseño y Limitaciones

### Bank Cap solo para ETH

- Los límites en USD aplican únicamente a ETH.
- Tokens ERC-20 no poseen cap hasta implementar oráculos individuales.

### Oráculo sin validación de frescura

- No se verifica si el precio está desactualizado.
- Mitigación futura: validar `updatedAt` y `answeredInRound`.

### `receive()` mientras está pausado

- Permite depósitos pasivos para evitar pérdida de ETH enviado accidentalmente.
- No permite retiros ni funciones activas durante pausa.

---

## 🧱 Información Técnica

**Versión Solidity:** ^0.8.30  
**Dependencias:** OpenZeppelin 5.0+, Chainlink Feeds  
**Oráculo ETH/USD (Sepolia):** `0x694AA1769357215DE4FAC081bf1f309aDC325306`  
**Dirección desplegada:** https://sepolia.etherscan.io/address/0xC58370BcFBF3Fb3557D286603a45a1b6Fd1C5d2a
**Contrato:** https://sepolia.etherscan.io/address/0xC58370BcFBF3Fb3557D286603a45a1b6Fd1C5d2a#code#F1#L2
**Licencia:** MIT
---

## 👨‍💻 Desarrollador

**Autor:** Marcelo Walter Castellan  
**GitHub:** [mwcastellan](https://github.com/mwcastellan)  
**Email:** mcastellan@yahoo.com  
**Fecha de actualización:** 02 de Noviembre de 2025
