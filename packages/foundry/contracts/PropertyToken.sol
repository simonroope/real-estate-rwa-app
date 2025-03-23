// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PropertyToken
 * @notice Immutable ERC1155 token contract for property shares
 * @dev This contract handles the core ERC1155 functionality
 */
contract PropertyToken is ERC1155 {
    using Strings for uint256;

    // Token configuration
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant TOKEN_AMOUNT = 1;
    uint256 public constant TOKEN_PRICE = 1000 * 10 ** 18; // 1000 USDC
    uint256 public constant TOKEN_SUPPLY = 1000;
    uint256 public constant TOKEN_DECIMALS = 18;
    string public constant TOKEN_SYMBOL = "PROP";
    string public constant TOKEN_NAME = "Property Token";

    constructor(string memory uri_) ERC1155(uri_) { }

    /**
     * @notice Get the URI for a token's metadata
     * @param tokenId Token ID to query
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(0), tokenId.toString()));
    }

    /**
     * @notice Mint tokens to an address
     * @param to Address to mint tokens to
     * @param tokenId Token ID to mint
     * @param amount Amount of tokens to mint
     * @param data Additional data to pass to receiver
     */
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external {
        _mint(to, tokenId, amount, data);
    }

    /**
     * @notice Burn tokens from an address
     * @param from Address to burn tokens from
     * @param tokenId Token ID to burn
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 tokenId, uint256 amount) external {
        _burn(from, tokenId, amount);
    }

    /**
     * @notice Safe transfer tokens from one address to another
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId Token ID to transfer
     * @param amount Amount of tokens to transfer
     * @param data Additional data to pass to receiver
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        virtual
        override
    {
        _safeTransferFrom(from, to, tokenId, amount, data);
    }
}
