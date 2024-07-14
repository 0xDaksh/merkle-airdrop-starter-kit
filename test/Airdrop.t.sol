// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Airdrop} from "./../src/Airdrop.sol";
import {MockToken} from "./../src/MockToken.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract AirdropTest is Test {
    MockToken public token;
    Airdrop public airdrop;

    function setUp() public {
        // Setup initial parameters for Airdrop
        address owner = address(this);
        address funder = address(this);
        bytes32 merkleRoot = bytes32(0x3fc8090ecab5ab64b34f4d075ee087dbe6a64f7ba054e686152f6defc0503855);

        // Deploy MockToken
        token = new MockToken("Test Token", "TEST");

        // Deploy Airdrop implementation
        Airdrop airdropImplementation = new Airdrop();

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin(owner);

        vm.warp(1641070800);
        uint256 start = block.timestamp - 1;
        uint256 end = start + 365 days;

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(airdropImplementation),
            address(proxyAdmin),
            abi.encodeWithSelector(Airdrop.initialize.selector, owner, address(token), funder, merkleRoot, start, end)
        );

        // Set airdrop to the proxy address
        airdrop = Airdrop(address(proxy));

        // Mint some tokens to the funder (this contract)
        token.mint(address(this), 18141900000000000000); // ~19 tokens

        // Approve airdrop contract to spend tokens
        token.approve(address(airdrop), type(uint256).max);
    }

    function testClaim() public {
        address user = 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5;
        uint256 amount = 3074000000000000000;
        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0x73d1a0c85445f9285d4564ec4ef41ec1bf7ee8a4b349a50a6e12176eab594b5b;
        proof[1] = 0x6a69081de7dd029f024f842849f303756bb5a2cc5ffc35212550bce6f3bad325;
        proof[2] = 0x9ff146ab8066c4fd65200349b430d60b02eab11a5979fbb9ecbb2dc5533e6845;

        bool valid = airdrop.verifyProof(user, amount, proof);
        assertTrue(valid);

        valid = airdrop.verifyProof(user, amount - 1, proof);
        assertFalse(valid);

        address[] memory users = new address[](1);
        users[0] = user;
        airdrop.disallowUsers(users, true);

        vm.expectRevert(Airdrop.UserNotAllowed.selector);
        vm.prank(user);
        airdrop.claim(amount, proof);

        airdrop.disallowUsers(users, false);

        vm.startPrank(user);

        vm.expectRevert(Airdrop.InvalidProof.selector);
        airdrop.claim(amount - 1, proof);

        assertEq(token.balanceOf(user), 0);
        airdrop.claim(amount, proof);
        assertEq(token.balanceOf(user), amount);

        vm.expectRevert(Airdrop.AlreadyClaimed.selector);
        airdrop.claim(amount, proof);

        vm.expectRevert(Airdrop.ClaimNotActive.selector);
        vm.warp(block.timestamp - 100);
        airdrop.claim(amount, proof);

        vm.expectRevert(Airdrop.ClaimNotActive.selector);
        vm.warp(block.timestamp + 366 days);
        airdrop.claim(amount, proof);

        vm.stopPrank();
    }
}
