// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Airdrop} from "./../src/Airdrop.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployAirdrop is Script {
    address public token;
    address public owner;
    address public funder;
    bytes32 public merkleRoot;
    uint256 public start;
    uint256 public end;

    function setUp() public {
        /// TODO: must set these values, to your intended values
        token = address(0); // placeholder
        owner = address(0); // placeholder
        funder = address(0); // placeholder
        merkleRoot = bytes32(0); // placeholder, you will get this from the generator folder

        start = block.timestamp; // start block = now
        end = block.timestamp + 1 days * 365; // end block = now + 365 days
    }

    function run() public returns (address, address, address) {
        vm.startBroadcast();
        address proxyAdmin = address(new ProxyAdmin(owner));
        address airdropImplementation = address(new Airdrop());

        address proxy = address(
            new TransparentUpgradeableProxy(
                airdropImplementation,
                proxyAdmin,
                abi.encodeWithSelector(Airdrop.initialize.selector, owner, token, funder, merkleRoot, start, end)
            )
        );

        vm.stopBroadcast();

        return (proxyAdmin, airdropImplementation, proxy);
    }
}
