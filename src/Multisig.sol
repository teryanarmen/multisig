// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {console} from "@std/console.sol";

contract Multisig {

    struct Action {
        address[] targets;
        uint256[] values;
        bytes[] data;
        uint8 votes;
    }

    event ActionProposed(uint256 id, Action action); // best practice?
    event ActionExecuted(uint256 id, Action action);
    event VoteCast(address signer, uint256 id);
    event SignerAdded(address signer, uint8 majority);
    event SignerRemoved(address signer, uint8 majority);

    mapping(address => bool) public signers;
    mapping(uint256 => Action) public actions;
    mapping(address => mapping(uint256 => bool)) public voted;
    uint8 public majority;
    uint8 public numSigners;

    modifier onlySigner() {
        require(signers[msg.sender], "not a signer");
        _;
    }

    modifier onlyContract() {
        require(msg.sender == address(this), "not this contract");
        _;
    }

    constructor(address[] memory _signers, uint8 _majority) payable {
        require(_signers.length > 0, "at least one signer needed");
        require(_majority > 0, "majority can not be zero");
        require(_majority <= _signers.length, "majority can not be greater than the number of signers");
        require(_majority > _signers.length/2, "majority must be greater than half");

        signers[address(this)] = true;
        for (uint256 i = 0; i < _signers.length;) {
            require(!signers[_signers[i]], "each signer can only be added once");
            signers[_signers[i]] = true;
            emit SignerAdded(_signers[i], _majority);
            unchecked { ++i; }
        }

        numSigners = uint8(_signers.length);
        majority = _majority;
    }

    function proposeAction(uint256 id, address[] calldata _targets, uint256[] calldata _values, bytes[] calldata _data) 
        external onlySigner {
        require(_targets.length == _values.length && _values.length == _data.length, "input length mismatch");
        require(actions[id].votes == 0, "an action already exists at given id");
        Action memory action;
        action.targets = _targets;
        action.values = _values;
        action.data = _data;
        action.votes = 1;
        actions[id] = action;
        voted[msg.sender][id] = true;
        emit ActionProposed(id, action);
        emit VoteCast(msg.sender, id);
    }

    function voteOnAction(uint256 _id) external onlySigner {
        require(!voted[msg.sender][_id], "already voted");
        voted[msg.sender][_id] = true;
        actions[_id].votes ++;
        emit VoteCast(msg.sender, _id);
    }

    function executeAction(uint256 _id) external {
        Action memory action = actions[_id];
        require(action.votes >= majority, "not enough votes");
        uint256 length = action.targets.length;
        for (uint256 i=0; i < length;) {
            (bool success, ) = address(action.targets[i]).call{value: action.values[i]}(action.data[i]);
            require(success, "call totally failed");
            console.log("here");
            unchecked { i++; }
        }
        emit ActionExecuted(_id, action);
        delete actions[_id];
    }

    function addSigner(address _signer, uint8 _majority) public onlyContract {
        require(_majority > numSigners/2, "not majority");
        signers[_signer] = true;
        numSigners++;
        majority = _majority;
        emit SignerAdded(_signer, _majority);
    }

    function removeSigner(address _signer, uint8 _majority) public onlyContract {
        require(signers[_signer], "not a signer");
        require(numSigners > 1, "cant have 0 signers");
        signers[_signer] = false;
        numSigners--;
        majority = _majority;
        emit SignerRemoved(_signer, _majority);
    }

    // getter functions
    function getActionTargets(uint256 id) public view returns(address[] memory) {
        return actions[id].targets;
    }

    function getActionValues(uint256 id) public view returns(uint256[] memory)  {
        return actions[id].values;
    }

    function getActionData(uint256 id) public view returns(bytes[] memory) {
        return actions[id].data;
    }
}
