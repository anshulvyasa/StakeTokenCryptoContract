// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract StakeToken is ERC20, Ownable {
    string public Token_IMAGE_URL;

    // Constructor that sets the token name, symbol, and owner of the contract.
    constructor() ERC20("StakeToken", "STK") Ownable(msg.sender) {}

    function changeTokenImageURL(string memory _newTokenImageUrl) public onlyOwner{
       Token_IMAGE_URL=_newTokenImageUrl;
    }

    // Function to mint new tokens (only callable by the owner).
    function mint(address _account, uint256 _value) public onlyOwner {
        _mint(_account, _value);
    }

    // Function to burn tokens from a specific address (only callable by the owner).
    function burn(address _account, uint256 _amount) public onlyOwner {
        _burn(_account, _amount);
    }

    //to transfer token to the recipient.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return super.transfer(recipient, amount);
    }

    // to know the balance of an particular account.
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    //to allow someone to spend on your behalf.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    //to set the amount that someone is allowded to take from your account.
    function approve(address spender, uint256 amount) public override returns (bool) {
        return super.approve(spender, amount);
    }

    // by using this function i can take fund from another's acccount if he allowded me to.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    // function that allow you to get symbol of the token
    function symbol() public view override returns (string memory) {
        return super.symbol();
    }

    // function to get the totalSupply of the token
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    // to get the name of the token 
    function name() public view override returns (string memory) {
        return super.name();
    }

    function getTokenImageUrl() public view returns(string memory imagUrl){
        return Token_IMAGE_URL;
    }
}
