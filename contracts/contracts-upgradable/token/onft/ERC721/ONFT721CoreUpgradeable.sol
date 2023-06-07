// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IONFT721CoreUpgradeable.sol";
import "../../../lzApp/NonblockingLzAppUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

abstract contract ONFT721CoreUpgradeable is Initializable, NonblockingLzAppUpgradeable, ERC165Upgradeable, IONFT721CoreUpgradeable {
    uint16 public constant FUNCTION_TYPE_SEND = 1;

    function __ONFT721CoreUpgradeable_init(address _lzEndpoint) internal onlyInitializing {
        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);
        __ONFT721CoreUpgradeable_init_unchained();
    }

    function __ONFT721CoreUpgradeable_init_unchained() internal onlyInitializing {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IONFT721CoreUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, bool _useZro, bytes memory _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(_toAddress, _tokenId);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenId, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

        bytes memory payload = abi.encode(_toAddress, _tokenId);

        _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, 0);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenId);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint tokenId) = abi.decode(_payload, (bytes, uint));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, tokenId);
        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId);
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId) internal virtual;

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _tokenId) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint[46] private __gap;
}
