// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.5.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";

contract lottery is ERC20, Ownable {
    // ====== Managment tokens

    // direccion contract
    address public nft;

    constructor() ERC20("Lottery", "JA") {
        _mint(address(this), 1000);
        nft = address(new mainERC721());
    }

    address public ganador;

    mapping(address => address) public usuario_contract;

    // token price

    function precioTokens(uint _numTokens) internal pure  returns (uint256) {
        return _numTokens * (1 ether);
    }

    // visualizacion de balance de token ERC-20 de un usuario
    function balanceTokens(address _account) public view returns (uint256){
        return balanceOf(_account);
    }

    // visualizacion de balance de token ERC-20 de un usuario Smart Contract
    function balanceTokensSC() public view returns (uint256){
        return balanceOf(address(this));
    }

    // visualizacion de el balance de ethers del Smart Contract

    function balanceEthersSC() public view returns (uint256){
        return address(this).balance/ 10**18;
    }

    // Generacion de nuevos Tokens ERC-20
    function mint(uint256 _cantidad) public onlyOwner {
        _mint(address(this), _cantidad);
    }

    //Registro de usuarios

    function registrar() internal {
        address addr_personal_contract = address(new boletoNFTs(msg.sender, address(this), nft));
        usuario_contract[msg.sender] = addr_personal_contract;
    }

    // INformacion de un usuario
    function usersInfo(address _account) public view returns (address){
        return usuario_contract[_account];
    }

    function compraToken(uint256 _numTokens) public payable {
        // registro usuario
        if(usuario_contract[msg.sender] == address(0)){
            registrar();
        }
        // estableciendo  coste de los tokens a comprar

        uint256 coste = precioTokens(_numTokens);
        // Evaluacion del dinero que el cliente paga por los tokens
        require(msg.value >= coste, "Compra menos tokens o paga con mas ethers");

        //Obtencion de numero tokens ERC dispoinibles
        uint256 balance = balanceTokensSC();
        require(_numTokens <= balance, "Compra un numero menor de tokens");
        //Devolucion del dinero sobrante
        uint256 returnValue = msg.value - coste;
        //El smart contract devuelve la cantidad restante
        payable(msg.sender).transfer(returnValue);
        //Envio de los tokens al cliente/usuario
        _transfer(address(this), msg.sender, _numTokens);
    }


    function devolverTokens(uint _numTokens) public payable {
        require(_numTokens >0, "Necesitas devolver un numero de tokens mayor a 0");
        // El usuario debe acreditar tener los tokens que quiere devolver
        require(_numTokens <= balanceTokens(msg.sender), " No tienes los tokens que deseas devolver");
        // El usuario transfiere los tokens al Smart Contract
        _transfer(msg.sender, address(this), _numTokens);
        // El smart Contract envia los ethers al usuario
        payable(msg.sender).transfer(precioTokens(_numTokens));
    }


    // =========== Gestion de la Loteria =======

    // Precio del boleto de loteria (en tokens ERC-20)

    uint public precioBoleto = 5;

    // Relacion: persona que compra los boletos -> el numero de los boletos
    mapping(address => uint[]) idPersona_boletos;
    //Relacion: boleto -> ganador
    mapping(uint => address) ADNBoleto;
    // Numero aleatorio
    uint randNonce = 0;
    // Boleto de la loteria generados
    uint [] boletosComprados;

    // Compra de boletos loteria

    function compraBoleto(uint _numBoletos) public {
        // Precio total boleto
        uint precioTotal = _numBoletos* precioBoleto;
        //verificacion tokens de usuario
        require(precioTotal <= balanceTokens(msg.sender), "No tienes tokens suficientes");
        // transferencia de tokens del usuario al Smart Contract
        _transfer(msg.sender, address(this), precioTotal);
        /*
          Recorre la marca de tiempo (block.timestamp) , msg.sender y un Nonce
          (numero que solo se utiliza una vez, para que no ejecutemos dos veces la misma 
          fucion de hash con los mismos parametros de entrada) en incremento.
          Seutiliza 'kekccak256' para convertir estas entradas a un hash aleatorio,
          converetir ese hash a un uint y luego utilizamos % 10000 para tomar los ultimos 4 digitos,
          dando un valor aleatorio entre 0 - 9999
        */
        for (uint i=0; i< _numBoletos; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender, randNonce))) % 10000;
            randNonce++;
            // Almacenamiento datos de boleto enlazado al usuario
            idPersona_boletos[msg.sender].push(random);
            // almacenamiento datos de boletos
            boletosComprados.push(random);
            // Asignacion del ADN del boleto para la generacion de un ganador
            ADNBoleto[random] = msg.sender;
            //Creacion d eun nuevo NFT para el numero de boleto
            boletoNFTs(usuario_contract[msg.sender]).mintBoleto(msg.sender, random);
        }
    }

    // visualizacion de los boletos del usuario
    function tusBoletos(address _propietario) public view returns(uint [] memory) {
        return idPersona_boletos[_propietario];
    }

    function generarGanador() public onlyOwner {
       
        // Declaracion de la longitud del array
        uint longitud = boletosComprados.length;
         // Verificacion de la compra de al menos 1 boleto
        require(longitud >0, "No hay boletos comprados");
        // Elecccion aleatoria de un numero entre: [0-Longitud]
        uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % longitud); 
        // Seleccion del numero aleatorio
        uint eleccion = boletosComprados[random];
        // Direccion del ganador de la loteria
        ganador = ADNBoleto[eleccion];
        // Envio del 95% del premio de la loteria al ganador
        payable(ganador).transfer(address(this).balance * 95/ 100);
        //Envio del 5 % del mpreio de loterial al owner
        payable(owner()).transfer(address(this).balance * 5 /100);
    }

    


}

// Smart contracto NFTS
contract mainERC721 is ERC721{
    address public direccionLoteria;

    constructor() ERC721("Lottery", "STE"){
        direccionLoteria = msg.sender;
    }

    //creacion NFTS
    function safeMint(address _propietario, uint256 _boleto) public {
        require(msg.sender == lottery(direccionLoteria).usersInfo(_propietario),
        "No tienes permiso para ejecutar esta funcionalidad");
        _safeMint(_propietario, _boleto);
    }
}

contract boletoNFTs {
    //Datos relevantes del propietario

    struct Owner{
        address direccionPropietario;
        address contratoPadre;
        address contratoNFT;
        address contratoUsuario;
    }

    Owner public propietario;

    //Constructor del Smart Contract (hijo)
    constructor(address _propietario, address _contratoPadre, address _contratoNFT){
        propietario = Owner(_propietario,_contratoPadre,_contratoNFT, address(this));
    }

    // Conversion los numeros de los boletos de loteria
    function mintBoleto(address _propietario, uint _boleto) public {
        require(msg.sender == propietario.contratoPadre, "No tienes permisos para ejecutar esta funcion");
        mainERC721(propietario.contratoNFT).safeMint(_propietario, _boleto);
        
    }
}