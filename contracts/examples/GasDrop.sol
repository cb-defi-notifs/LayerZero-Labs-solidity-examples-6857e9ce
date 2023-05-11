// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lzApp/NonblockingLzApp.sol";

contract GasDrop is NonblockingLzApp {
    uint16 public constant VERSION = 2;
    uint public dstGas = 25000;

    event SendGasDrop(uint16 indexed _dstChainId, address indexed _from, bytes indexed _toAddress, uint _amount);
    event ReceiveGasDrop(uint16 indexed _srcChainId, address indexed _from, bytes indexed _toAddress, uint _amount);

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _amount, bool _useZro) external view virtual returns (uint nativeFee, uint zroFee) {
        bytes memory adapterParams = abi.encodePacked(VERSION, dstGas, _amount, _toAddress);
        bytes memory payload = abi.encode(_amount, msg.sender, _toAddress);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, adapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (uint amount, address fromAddress, bytes memory toAddress) = abi.decode(_payload, (uint, address, bytes));
        emit ReceiveGasDrop(_srcChainId, fromAddress, toAddress, amount);
    }

    function gasDrop(uint16 _dstChainId, bytes memory _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress) external payable virtual {
        bytes memory adapterParams = abi.encodePacked(VERSION, dstGas, _amount, _toAddress);
        bytes memory payload = abi.encode(_amount, msg.sender, _toAddress);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, adapterParams, msg.value);
        emit SendGasDrop(_dstChainId, msg.sender, _toAddress, _amount);
    }

    function setDstGas(uint _dstGas) external onlyOwner {
        dstGas = _dstGas;
    }
}