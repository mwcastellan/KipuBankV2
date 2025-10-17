KipuBankV2
Descripción del Proyecto
KipuBankV2 es la evolución mejorada del contrato original KipuBank. Esta versión incorpora funcionalidades avanzadas como soporte para múltiples tokens ERC-20, integración con oráculos de Chainlink para conversión de precios, y un sistema de control de acceso robusto para operaciones administrativas.

Mejoras Principales Implementadas
1. Control de Acceso y Seguridad
Problema en V1: No había forma de pausar el contrato en caso de emergencia ni restricciones para funciones administrativas.

Solución en V2:

Integración de Ownable de OpenZeppelin para gestión administrativa
Agregado de Pausable para pausar operaciones en emergencias
ReentrancyGuard para protección contra ataques de reentrada
Solo el owner puede modificar parámetros del banco
Beneficio: Mayor seguridad y capacidad de respuesta ante situaciones críticas.

2. Soporte Multi-Token
Problema en V1: Solo se podía depositar y retirar ETH nativo.

Solución en V2:

Sistema de whitelist con isTokenSupported
Mapping anidado s_userBalances[usuario][token] para contabilidad
Funciones separadas: depositNative() y depositToken()
Uso de SafeERC20 para transferencias seguras
Patrón "balance difference" para tokens con fee-on-transfer
Beneficio: Los usuarios pueden gestionar múltiples activos en una sola plataforma.

3. Integración con Chainlink Oracle
Problema en V1: Los límites estaban en ETH, causando inconsistencias cuando el precio variaba.

Solución en V2:

Integración de Chainlink Price Feed para ETH/USD
Bank cap y withdrawal limit expresados en USD
Conversión automática en cada operación con ETH
Beneficio: Límites consistentes independientemente de la volatilidad del precio de ETH.

4. Convenciones de Código y Buenas Prácticas
Mejoras implementadas:

Variables inmutables con prefijo i_ (ejemplo: i_priceFeed)
Variables de storage con prefijo s_ (ejemplo: s_bankCapUSD)
Variables privadas con getters públicos para mejor encapsulación
Errores personalizados con prefijo del contrato (ejemplo: KipuBank__ZeroAmount)
Modificadores para validaciones reutilizables
Beneficio: Código más legible, mantenible y siguiendo estándares de la industria.

5. Gestión Administrativa Mejorada
Nuevas funciones administrativas:

supportNewToken(): Agregar tokens a la whitelist
removeTokenSupport(): Remover tokens de la whitelist
updateBankCap(): Actualizar capacidad máxima
updateWithdrawalLimit(): Actualizar límite de retiros
pauseBank() / unpauseBank(): Control de emergencia
6. Estadísticas y Eventos Mejorados
Eventos detallados:

Deposit: Incluye usuario, token, cantidad y valor USD
Withdrawal: Información completa de retiros
TokenSupported / TokenRemoved: Cambios en whitelist
BankCapUpdated / WithdrawalLimitUpdated: Cambios administrativos
Contadores:

s_totalDeposits: Total de operaciones de depósito
s_totalWithdrawals: Total de operaciones de retiro
Estructura del Contrato
Orden de Organización del Código
El contrato sigue el orden estándar recomendado:

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
Convenciones de Nomenclatura
Immutable: Prefijo i_ → i_priceFeed
Storage: Prefijo s_ → s_bankCapUSD
Internal/Private: Prefijo _ → _getUSDValue()
Constants: MAYÚSCULAS → NATIVE_TOKEN
Errores: ContractName__ErrorName → KipuBank__ZeroAmount
Instrucciones de Despliegue
Prerequisitos
Tener instalado Remix IDE o Hardhat
MetaMask configurado con testnet (Sepolia recomendada)
ETH de testnet para gas fees
Dependencias
El contrato requiere las siguientes librerías:

@openzeppelin/contracts/access/Ownable.sol
@openzeppelin/contracts/security/Pausable.sol
@openzeppelin/contracts/security/ReentrancyGuard.sol
@openzeppelin/contracts/token/ERC20/IERC20.sol
@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
Dirección del Oracle Chainlink
Sepolia Testnet - ETH/USD:

0x694AA1769357215DE4FAC081bf1f309aDC325306
Parámetros del Constructor
constructor(
    uint256 _bankCapUSD,           // Ejemplo: 100000000000 = $1,000 USD (8 decimales)
    uint256 _withdrawalLimitUSD,   // Ejemplo: 10000000000 = $100 USD (8 decimales)
    address _priceFeedAddress      // 0x694AA1769357215DE4FAC081bf1f309aDC325306 para Sepolia
)
Nota importante sobre decimales: Los valores USD deben tener 8 decimales (formato del oracle de Chainlink).

Proceso de Despliegue en Remix
Abrir Remix IDE (https://remix.ethereum.org)

Crear el archivo: src/KipuBankV2.sol

Compilar el contrato:

Seleccionar compilador 0.8.19
Hacer clic en "Compile"
Conectar MetaMask:

Cambiar a Sepolia testnet
Asegurar tener ETH de prueba
Deploy:

Ir a "Deploy & Run Transactions"
Seleccionar "Injected Provider - MetaMask"
Ingresar parámetros del constructor:
_bankCapUSD: 100000000000
_withdrawalLimitUSD: 10000000000
_priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
Hacer clic en "Deploy"
Confirmar en MetaMask
Verificar el contrato en Sepolia Etherscan

Cómo Interactuar con el Contrato
Para Usuarios Regulares
Depositar ETH:

// Opción 1: Llamar a depositNative()
depositNative{value: 0.1 ether}();

// Opción 2: Enviar ETH directamente (vía receive)
// El contrato lo procesará automáticamente
Depositar Tokens ERC-20:

// Paso 1: Aprobar el token
IERC20(tokenAddress).approve(kipuBankV2Address, cantidad);

// Paso 2: Depositar
depositToken(tokenAddress, cantidad);
Retirar ETH:

withdrawNative(cantidadEnWei);
Retirar Tokens:

withdrawToken(tokenAddress, cantidad);
Consultar Balances:

// Mi balance de ETH
getMyBalance(address(0));  // address(0) = NATIVE_TOKEN

// Mi balance de un token
getMyBalance(tokenAddress);

// Balance de otro usuario
getBalance(usuarioAddress, tokenAddress);
Ver Precio de ETH:

getETHPrice();  // Retorna precio con 8 decimales
Ver Estadísticas:

getBankStats();  // Retorna (totalDeposits, totalWithdrawals)
Para el Owner (Administrador)
Agregar Token a la Whitelist:

supportNewToken(tokenAddress);
Remover Token:

removeTokenSupport(tokenAddress);
Actualizar Bank Cap:

updateBankCap(nuevaCapacidadUSD);  // 8 decimales
Actualizar Límite de Retiro:

updateWithdrawalLimit(nuevoLimiteUSD);  // 8 decimales
Pausar el Banco:

pauseBank();
Reanudar Operaciones:

unpauseBank();
Decisiones de Diseño y Trade-offs
1. Sistema de Whitelist para Tokens
Decisión: Los tokens deben ser explícitamente aprobados por el owner antes de ser depositados.

Razón: Prevenir que tokens maliciosos o con comportamientos extraños sean depositados en el banco.

Trade-off:

✅ Mayor seguridad y control
⚠️ Requiere gestión activa del owner
⚠️ Menos permissionless
2. Patrón "Balance Difference" en depositToken()
Decisión: Calcular la cantidad real recibida midiendo el balance antes y después de la transferencia.

Razón: Soportar tokens con fee-on-transfer (como algunos tokens de reflexión).

Código:

uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));
IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
uint256 amountReceived = balanceAfter - balanceBefore;
Trade-off:

✅ Funciona con tokens fee-on-transfer
⚠️ Técnicamente viola Checks-Effects-Interactions
✅ Protegido por nonReentrant
3. Variables Privadas con Getters
Decisión: Hacer variables de estado privadas y exponer getters específicos.

Razón: Mejor encapsulación y control sobre cómo se accede a los datos.

Trade-off:

✅ Más control y flexibilidad
✅ Posibilidad de agregar lógica en getters
⚠️ Requiere más funciones view
4. Oracle Único para ETH
Decisión: Solo integrar oracle de Chainlink para ETH/USD, no para tokens ERC-20.

Razón: Simplificación para MVP y enfoque en funcionalidad core.

Limitación reconocida: Los tokens ERC-20 no tienen conversión a USD, por lo que el bank cap no se aplica a ellos en esta versión.

Mejora futura: Agregar múltiples oracles para cada token soportado.

Características de Seguridad
Protecciones Implementadas
ReentrancyGuard: Todas las funciones que transfieren fondos usan nonReentrant

SafeERC20: Previene problemas con tokens que no retornan boolean

Pausable: Permite detener operaciones en emergencias

Validaciones de precio: Verifica que el precio del oracle sea mayor a 0

Custom Errors: Ahorro de gas y mejor información de errores

Uso de call() para ETH:

(bool success, ) = _to.call{value: _amount}("");
if (!success) {
    revert KipuBank__TransferFailed();
}
Patrón Checks-Effects-Interactions
Las funciones de retiro siguen este patrón:

// Checks
if (s_userBalances[msg.sender][NATIVE_TOKEN] < _amount) {
    revert KipuBank__InsufficientBalance();
}

// Effects
s_userBalances[msg.sender][NATIVE_TOKEN] -= _amount;
s_totalWithdrawals++;

// Interactions
_transferNative(msg.sender, _amount);
Excepción: depositToken() usa balance difference por necesidad técnica, pero está protegido por nonReentrant.

Casos de Prueba
Flujo Básico
✅ Depositar 0.1 ETH → Balance aumenta, evento emitido
✅ Retirar 0.05 ETH → Balance disminuye, ETH recibido
✅ Consultar balance → Muestra valor correcto
✅ Ver precio ETH → Muestra precio actual del oracle
Validaciones
✅ Depositar más del bank cap → Falla con KipuBank__BankCapExceeded
✅ Retirar más del balance → Falla con KipuBank__InsufficientBalance
✅ Retirar más del límite USD → Falla con KipuBank__WithdrawalLimitExceeded
✅ Depositar 0 ETH → Falla con KipuBank__ZeroAmount
Tokens ERC-20
✅ Agregar token a whitelist (owner) → Exitoso
✅ Depositar token no soportado → Falla con KipuBank__TokenNotSupported
✅ Depositar token soportado → Balance aumenta
✅ Intentar usar depositNative para token → Falla con error específico
Control de Acceso
✅ Owner pausa el banco → Exitoso
✅ Intentar depositar con banco pausado → Falla
✅ Usuario normal intenta pausar → Falla con revert de Ownable
✅ Owner actualiza bank cap → Exitoso, evento emitido
Limitaciones Conocidas
1. Bank Cap No Aplicado a Tokens ERC-20
Problema: Solo se valida el bank cap para ETH, no para tokens ERC-20.

Razón: Requiere integrar oracles de precio para cada token, lo cual está fuera del scope de esta versión.

Impacto: Los usuarios podrían depositar cantidades ilimitadas de tokens ERC-20.

Mitigación: El sistema de whitelist permite controlar qué tokens se aceptan.

2. No Hay Validación de Staleness del Oracle
Problema: No se verifica si los datos del oracle están desactualizados.

Impacto potencial: En caso de que el oracle falle, podrían usarse datos obsoletos.

Mejora sugerida:

(, int256 price, , uint256 updatedAt, ) = i_priceFeed.latestRoundData();
if (price <= 0) revert KipuBank__OracleFailed("Invalid oracle price");
// Agregar validación de tiempo
if (block.timestamp - updatedAt > 3600) {
    revert KipuBank__OracleFailed("Stale oracle data");
}
3. Conversión USD Solo para ETH
Limitación: Los valores en USD solo se calculan para ETH nativo, no para tokens ERC-20.

Razón: Simplificación del alcance y enfoque en el caso de uso principal.

Mejora futura: Implementar sistema de múltiples price feeds para cada token.

Comparación con KipuBank V1
Característica	V1	V2
Soporte Multi-Token	❌ Solo ETH	✅ ETH + ERC-20
Oracle de Precios	❌ No	✅ Chainlink
Control de Acceso	❌ No	✅ Ownable + Pausable
Protección Reentrancy	❌ No	✅ ReentrancyGuard
Custom Errors	✅ Parcial	✅ Completo
Convenciones de Código	⚠️ Básicas	✅ Estándares industria
Límites en USD	❌ En ETH	✅ En USD
Whitelist de Tokens	❌ No	✅ Sí
Eventos Detallados	⚠️ Básicos	✅ Completos
Funciones Administrativas	❌ No	✅ Múltiples
Información del Contrato Desplegado
Red: Sepolia Testnet

Dirección del Contrato: 0x8bb00bf443e2c06f54c603f70ae75af04122b567

Explorador: https://sepolia.etherscan.io/tx/0xfb1bd8d5cb32aface1447a96a146c3d12ed35a92cba8470e7c0186056ffd32b7

Código Verificado: Sí

Parámetros Utilizados en el Despliegue
Bank Cap: 100,000,000,000 wei (1,000 USD con 8 decimales)
Withdrawal Limit: 10,000,000,000 wei (100 USD con 8 decimales)
Price Feed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 (Sepolia ETH/USD)
Roadmap Futuro (V3)
Posibles mejoras para futuras versiones:

Múltiples Oracles: Integrar price feeds para cada token ERC-20 soportado
Validación de Staleness: Verificar que los datos del oracle no estén desactualizados
Bank Cap Multi-Token: Aplicar límite global considerando todos los tokens
Sistema de Rewards: Implementar intereses por mantener fondos depositados
Governance: Sistema de votación descentralizado para cambios importantes del protocolo
Liquidez y Staking: Permitir que usuarios provean liquidez y obtengan recompensas
Multi-Chain: Desplegar en múltiples redes (Ethereum, Polygon, Arbitrum)
Tecnologías y Herramientas Utilizadas
Solidity: ^0.8.19
OpenZeppelin Contracts: v4.9.0+
Ownable
Pausable
ReentrancyGuard
SafeERC20
Chainlink: Price Feeds para ETH/USD
Remix IDE: Desarrollo y testing
MetaMask: Interacción con blockchain
Sepolia Testnet: Red de prueba
Recursos Adicionales
Documentación Oficial
OpenZeppelin Contracts
Chainlink Price Feeds
Solidity Documentation
Tutoriales Relacionados
Chainlink Price Feeds Tutorial
OpenZeppelin Access Control
SafeERC20 Guide
Preguntas Frecuentes (FAQ)
P: ¿Por qué usar address(0) para ETH en lugar de WETH?
R: Por simplicidad y para evitar pasos adicionales de wrapping/unwrapping. Los usuarios pueden depositar ETH directamente.

P: ¿Qué pasa si el oracle de Chainlink falla?
R: El contrato revertirá con KipuBank__OracleFailed y no permitirá depósitos de ETH hasta que el oracle se recupere.

P: ¿Puedo depositar cualquier token ERC-20?
R: No, solo tokens que hayan sido agregados a la whitelist por el owner mediante supportNewToken().

P: ¿Por qué hay funciones separadas para ETH y tokens?
R: Para mayor claridad y seguridad. ETH requiere funciones payable, mientras que tokens usan transferFrom.

P: ¿Qué son los prefijos i_ y s_ en las variables?
R: Son convenciones estándar: i_ para immutable y s_ para storage. Mejora la legibilidad del código.

P: ¿Puedo retirar más del límite de retiro?
R: No, el límite está establecido en USD para proteger contra volatilidad. El owner puede actualizarlo si es necesario.

Contribuciones
Este proyecto es parte de un proceso de aprendizaje en desarrollo Web3. Sugerencias y mejoras son bienvenidas.

Licencia
MIT License - Ver archivo LICENSE para más detalles

Contacto y Soporte
Desarrollador: Darío Echeverría Muñoz

GitHub: IusLedger

Email: dario@qqrucho.org

Fecha de Desarrollo: Octubre 2025

Agradecimientos
Equipo de OpenZeppelin por las librerías de contratos
Chainlink por los oracles de datos confiables
Comunidad de Ethereum por el soporte y documentación
Instructores del curso por la guía y feedback
Nota Final: Este contrato ha sido desarrollado con fines educativos. Aunque implementa muchas buenas prácticas de seguridad, se recomienda una auditoría profesional antes de usar en producción con fondos reales.
