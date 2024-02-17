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


}

contract mainERC721 is ERC721{
    constructor() ERC721("Lottery", "STE"){}
}