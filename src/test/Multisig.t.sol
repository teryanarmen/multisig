// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Multisig} from "../Multisig.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

contract MultisigTest is DSTestPlus {
    Multisig multisig;
    function setUp() public {}

    function testSetup(address initialSigner, address notYetSigner, address neverSigner) public {
        // assume
        vm.assume(initialSigner != notYetSigner);
        vm.assume(initialSigner != neverSigner);
        vm.assume(notYetSigner != neverSigner);

        // set up
        address[] memory signers = new address[](1);
        signers[0] = initialSigner;
        multisig = new Multisig(signers, 1);

        // assert
        assertTrue(multisig.signers(initialSigner), "address should be signer");
        assertTrue(!multisig.signers(notYetSigner), "address should not be signer");
        assertTrue(!multisig.signers(neverSigner), "address should not be signer");

        // set up variables
        address[] memory targets = new address[](2);
        targets[0] = address(multisig);
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("addSigner(address,uint8)", notYetSigner, 2);
        
        // add signer
        vm.prank(initialSigner);
        multisig.proposeAction(0, targets, values, data);
        multisig.executeAction(0);
        

        // check if updated correctly
        assertTrue(multisig.signers(notYetSigner), "address should be signer");
        assertTrue(!multisig.signers(neverSigner), "address should not be signer");
    }
}