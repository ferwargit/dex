// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SimpleDEX
/// @author Fernando Warno
/// @notice Este contrato implementa un intercambio descentralizado simple (DEX)
/// @dev Incluye protección contra ataques de reentrancy
contract SimpleDEX is Ownable, ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );
    event TokensSwapped(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice Constructor que inicializa el contrato con las direcciones de los tokens
    /// @param _tokenA Dirección del token A
    /// @param _tokenB Dirección del token B
    /// @param initialOwner Dirección del propietario inicial del contrato
    constructor(
        address _tokenA,
        address _tokenB,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_tokenA != address(0), "Token A no puede ser address zero");
        require(_tokenB != address(0), "Token B no puede ser address zero");
        require(_tokenA != _tokenB, "Los tokens deben ser diferentes");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Función para agregar liquidez al DEX
    /// @param amountA Cantidad de token A a agregar
    /// @param amountB Cantidad de token B a agregar
    /// @dev Incluye nonReentrant para prevenir ataques de reentrancy
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) public onlyOwner nonReentrant {
        require(
            amountA > 0 && amountB > 0,
            "Los importes deben ser mayores que cero"
        );

        // Primero actualizamos el estado
        reserveA += amountA;
        reserveB += amountB;

        // Luego realizamos las transferencias externas
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "Transferencia de token A fallida"
        );
        require(
            tokenB.transferFrom(msg.sender, address(this), amountB),
            "Transferencia de token B fallida"
        );

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /// @notice Función para intercambiar token A por token B
    /// @param amountAIn Cantidad de token A a intercambiar
    /// @dev Incluye nonReentrant y checks de seguridad adicionales
    function swapAforB(uint256 amountAIn) public nonReentrant {
        require(amountAIn > 0, "El importe debe ser mayor que cero");
        require(
            reserveA > 0 && reserveB > 0,
            "La liquidez debe ser mayor que cero"
        );

        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        require(amountBOut > 0, "Salida calculada demasiado baja");
        require(amountBOut < reserveB, "Salida excede reservas");

        // Actualizamos el estado antes de las transferencias externas
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // Realizamos las transferencias externas
        require(
            tokenA.transferFrom(msg.sender, address(this), amountAIn),
            "Transferencia de entrada fallida"
        );
        require(
            tokenB.transfer(msg.sender, amountBOut),
            "Transferencia de salida fallida"
        );

        emit TokensSwapped(msg.sender, amountAIn, amountBOut);
    }

    /// @notice Función para intercambiar token B por token A
    /// @param amountBIn Cantidad de token B a intercambiar
    /// @dev Incluye nonReentrant y checks de seguridad adicionales
    function swapBforA(uint256 amountBIn) public nonReentrant {
        require(amountBIn > 0, "El importe debe ser mayor que cero");
        require(
            reserveA > 0 && reserveB > 0,
            "La liquidez debe ser mayor que cero"
        );

        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        require(amountAOut > 0, "Salida calculada demasiado baja");
        require(amountAOut < reserveA, "Salida excede reservas");

        // Actualizamos el estado antes de las transferencias externas
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // Realizamos las transferencias externas
        require(
            tokenB.transferFrom(msg.sender, address(this), amountBIn),
            "Transferencia de entrada fallida"
        );
        require(
            tokenA.transfer(msg.sender, amountAOut),
            "Transferencia de salida fallida"
        );

        emit TokensSwapped(msg.sender, amountBIn, amountAOut);
    }

    /// @notice Función para retirar liquidez del DEX
    /// @param amountA Cantidad de token A a retirar
    /// @param amountB Cantidad de token B a retirar
    /// @dev Incluye nonReentrant para prevenir ataques de reentrancy
    function removeLiquidity(
        uint256 amountA,
        uint256 amountB
    ) public onlyOwner nonReentrant {
        require(
            amountA > 0 && amountB > 0,
            "Los importes deben ser mayores que cero"
        );
        require(
            reserveA >= amountA && reserveB >= amountB,
            "Liquidez insuficiente"
        );

        // Actualizamos el estado antes de las transferencias externas
        reserveA -= amountA;
        reserveB -= amountB;

        // Realizamos las transferencias externas
        require(
            tokenA.transfer(msg.sender, amountA),
            "Transferencia de token A fallida"
        );
        require(
            tokenB.transfer(msg.sender, amountB),
            "Transferencia de token B fallida"
        );

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /// @notice Función para obtener el precio de un token en función de las reservas
    /// @param _token Dirección del token para obtener el precio
    /// @return Precio del token en unidades de otro token
    function getPrice(address _token) public view returns (uint256) {
        require(
            _token == address(tokenA) || _token == address(tokenB),
            "Direccion de token no valida"
        );
        require(reserveA > 0 && reserveB > 0, "Reservas insuficientes");

        return
            _token == address(tokenA)
                ? (reserveB * 1e18) / reserveA
                : (reserveA * 1e18) / reserveB;
    }
}
