// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TokenB
/// @author Fernando Warno
/// @notice Este contrato implementa un token ERC20 llamado TokenB con características mejoradas de seguridad
/// @dev Hereda de ERC20, Ownable, Pausable y ReentrancyGuard de OpenZeppelin
contract TokenB is ERC20, Ownable, Pausable, ReentrancyGuard {
    // Constantes
    uint256 public constant MAX_SUPPLY = 1000000 * 10 ** 18; // 1 millón de tokens
    uint256 public constant MAX_TRANSACTION_LIMIT = 10000 * 10 ** 18; // 10,000 tokens

    // Variables de estado
    uint256 public totalMinted;

    // Eventos
    event MintingPaused(address indexed by);
    event MintingResumed(address indexed by);
    event TransactionLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event TokensMinted(
        address indexed to,
        uint256 amount,
        uint256 newTotalSupply
    );
    event TokensBurned(
        address indexed from,
        uint256 amount,
        uint256 newTotalSupply
    );

    /// @notice Constructor que inicializa el token y establece el propietario inicial
    /// @param initialOwner Dirección del propietario inicial del contrato
    constructor(
        address initialOwner
    ) ERC20("TokenB", "TK-B") Ownable(initialOwner) {
        totalMinted = 0;
    }

    /// @notice Función para pausar todas las operaciones del token
    /// @dev Solo puede ser llamada por el propietario
    function pause() external onlyOwner {
        _pause();
        emit MintingPaused(msg.sender);
    }

    /// @notice Función para reanudar las operaciones del token
    /// @dev Solo puede ser llamada por el propietario
    function unpause() external onlyOwner {
        _unpause();
        emit MintingResumed(msg.sender);
    }

    /// @notice Función para acuñar nuevos tokens
    /// @param to Dirección a la que se acuñarán los tokens
    /// @param amount Cantidad de tokens a acuñar
    /// @dev Solo el propietario puede llamar a esta función
    function mint(
        address to,
        uint256 amount
    ) public onlyOwner whenNotPaused nonReentrant {
        require(to != address(0), "No se puede mintear a la direccion cero");
        require(amount > 0, "La cantidad debe ser mayor a cero");
        require(
            amount <= MAX_TRANSACTION_LIMIT,
            "Excede el limite por transaccion"
        );
        require(
            totalMinted + amount <= MAX_SUPPLY,
            "Excederia el suministro maximo"
        );

        totalMinted += amount;
        _mint(to, amount);

        emit TokensMinted(to, amount, totalSupply());
    }

    /// @notice Función para quemar tokens
    /// @param amount Cantidad de tokens a quemar
    /// @dev Cualquier holder puede quemar sus propios tokens
    function burn(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "La cantidad debe ser mayor a cero");
        require(
            amount <= MAX_TRANSACTION_LIMIT,
            "Excede el limite por transaccion"
        );

        _burn(_msgSender(), amount);
        totalMinted -= amount;

        emit TokensBurned(_msgSender(), amount, totalSupply());
    }

    /// @notice Sobreescribe la función de transferencia para incluir límites y pausabilidad
    /// @param to Dirección destinataria
    /// @param amount Cantidad a transferir
    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        require(
            amount <= MAX_TRANSACTION_LIMIT,
            "Excede el limite por transaccion"
        );
        return super.transfer(to, amount);
    }

    /// @notice Sobreescribe la función de transferFrom para incluir límites y pausabilidad
    /// @param from Dirección origen
    /// @param to Dirección destinataria
    /// @param amount Cantidad a transferir
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        require(
            amount <= MAX_TRANSACTION_LIMIT,
            "Excede el limite por transaccion"
        );
        return super.transferFrom(from, to, amount);
    }

    /// @notice Función para obtener la cantidad total de tokens en circulación
    /// @return uint256 Cantidad total de tokens
    function getCurrentSupply() public view returns (uint256) {
        return totalSupply();
    }

    /// @notice Función para obtener el espacio disponible para minteo
    /// @return uint256 Cantidad de tokens que aún se pueden mintear
    function getRemainingMintableSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted;
    }
}
