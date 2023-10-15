// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract WrappedEther is ERC20 {
    event Deposit(address indexed from, uint256 indexed amount);
    event Withdraw(address indexed to, uint256 indexed amount);

    constructor() ERC20("WrappedEther", "WETH") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}
