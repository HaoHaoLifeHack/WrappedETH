// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/WrappedETH.sol";
import {Test, console2} from "forge-std/Test.sol";

contract WrappedEtherTest is Test {
    event Deposit(address indexed from, uint256 indexed amount); //indexed 將參數宣告為index, 有宣告者會放在topic, 沒有的會放在data,可以更容易filter事件
    event Withdraw(address indexed to, uint256 indexed amount);

    address alice = makeAddr("Alice");
    address tom = makeAddr("tom");
    WrappedEther public wEth;
    uint256 initAmount = 1 ether;

    function setUp() public {
        wEth = new WrappedEther();
        vm.label(alice, "Alice");
        vm.label(tom, "Tom");
        deal(alice, initAmount);
        deal(address(wEth), initAmount);
        deal(address(wEth), alice, initAmount); // 一開始就從alice轉入initAmount eth 給wEth
    }

    function testDeposit(uint256 _amount) external {
        uint256 aliceBalanceBefore = wEth.balanceOf(alice);
        uint256 contractBalanceBefore = address(wEth).balance;

        _amount = bound(_amount, 1, initAmount); //限制_amount 介於1 ~ initAmount 之間
        // 測項 3: deposit 應該要 emit Deposit event
        vm.expectEmit(true, true, false, false); //check
        emit Deposit(alice, _amount);
        vm.prank(alice);
        wEth.deposit{value: _amount}();
        // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(wEth.balanceOf(alice) - aliceBalanceBefore, _amount);
        // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(address(wEth).balance - contractBalanceBefore, _amount);
    }

    function testWithdraw(uint256 _amount) external {
        uint256 aliceWETHBefore = wEth.balanceOf(alice);
        uint256 aliceBalanceBefore = alice.balance;
        uint256 contractBalanceBefore = address(wEth).balance;

        _amount = bound(_amount, 1, initAmount);
        // - 測項 6: withdraw 應該要 emit Withdraw event
        vm.expectEmit(true, true, false, false);
        emit Withdraw(alice, _amount);
        vm.prank(alice);
        wEth.withdraw(_amount);

        // - 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        assertEq(contractBalanceBefore - address(wEth).balance, _amount);

        // - 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(_amount, alice.balance - aliceWETHBefore);
    }

    function testTransfer(uint256 _amount) external {
        //transfer(address from, address to, uint256 value
        //- 測項 7: transfer 應該要將 erc20 token 轉給別人
        uint256 tomWEthBalance = wEth.balanceOf(tom);
        uint256 aliceWEthBalance = wEth.balanceOf(alice);
        _amount = bound(_amount, 1, initAmount);

        vm.prank(alice);
        wEth.transfer(tom, _amount);
        assertEq(wEth.balanceOf(tom) - tomWEthBalance, _amount);
        assertEq(aliceWEthBalance - wEth.balanceOf(alice), _amount);
    }

    function testApprove(uint256 _amount) external {
        //- 測項 8: approve 應該要給他人 allowance
        _amount = bound(_amount, 1, initAmount);
        uint256 allowanceBefore = wEth.allowance(alice, tom); //owner, spender
        vm.prank(alice);
        wEth.approve(tom, _amount);
        assertEq(allowanceBefore, wEth.allowance(alice, tom) - _amount);
    }

    function testTransferFrom(
        uint256 _allowance,
        uint256 _transferAmount
    ) external {
        _allowance = bound(_allowance, 1, initAmount);
        vm.prank(alice);
        wEth.approve(tom, _allowance);

        //- 測項 9: transferFrom 應該要可以使用他人的 allowance
        uint256 allowanceBefore = wEth.allowance(alice, tom);
        _transferAmount = bound(_transferAmount, 1, _allowance);
        vm.prank(tom);
        wEth.transferFrom(alice, tom, _transferAmount);

        //- 測項 10: transferFrom 後應該要減除用完的 allowance
        uint256 allowanceAfter = wEth.allowance(alice, tom);
        assertEq(allowanceAfter, allowanceBefore - _transferAmount);
    }
}
