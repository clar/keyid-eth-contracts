pragma solidity ^0.5.4;

import "./utils/MultiOwned.sol";
import "./Account.sol";
import "./AccountProxy.sol";

contract AccountCreator is MultiOwned {

    address public logicManager;
    address public accountStorage;
    address public accountImpl;

    // *************** Events *************************** //
    event AccountCreated(address indexed wallet, address[] keys, address[] backups);
    event AddressesSet(address mgr, address strg);

    // *************** Constructor ********************** //
    constructor(address _mgr, address _storage, address _accountImpl) public {
        logicManager = _mgr;
        accountStorage = _storage;
        accountImpl = _accountImpl;
    }

    // *************** Internal Functions ********************* //

    /**
     * @dev Initialize an account.
     * @param _accountProxy The account address.
     * @param _keys The initial keys.
     * @param _backups The initial backups.
     */
    function initializeAccount(address payable _accountProxy, address[] memory _keys, address[] memory _backups) internal {
        Account(_accountProxy).init(logicManager, accountStorage, LogicManager(logicManager).getAuthorizedLogics(), _keys, _backups);
        emit AccountCreated(_accountProxy, _keys, _backups);
    }

    // *************** External Functions ********************* //

    /**
     * @dev Method to create an account. Called only by owners.
     * create and initialize account in one transaction
     * This avoids race condition on Account.init
     * @param _keys The initial keys.
     * @param _backups The initial backups.
     */
    function createAccount(address[] calldata _keys, address[] calldata _backups) external onlyMultiOwners {
        AccountProxy accountProxy = new AccountProxy(accountImpl);
        initializeAccount(address(accountProxy), _keys, _backups);
    }

    /**
     * @dev method to create an account at a specific address.
     * The account is initialised with a list of keys and backups.
     * The account is created using the CREATE2 opcode.
     * @param _keys The list of keys.
     * @param _backups The list of backups.
     * @param _salt The salt.
     */
    function createCounterfactualAccount(address[] calldata _keys, address[] calldata _backups, bytes32 _salt) external onlyMultiOwners {
        // better to use abi.encode to eliminate potential collision
        bytes32 accountID = keccak256(abi.encode(_keys, _backups));
        bytes32 newSalt = keccak256(abi.encode(accountID, _salt)); // _salt used for zkSync PublicKey

        bytes memory code = abi.encodePacked(type(AccountProxy).creationCode, uint256(accountImpl));
        address payable accountProxy;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // create2(endowment, mem_start, mem_length, salt)
            accountProxy := create2(0, add(code, 0x20), mload(code), newSalt)
            if iszero(extcodesize(accountProxy)) { revert(0, returndatasize) }
        }
        initializeAccount(accountProxy, _keys, _backups);
    }

    function getCounterfactualAccountAddress(address[] calldata _keys, address[] calldata _backups, bytes32 _salt) external view returns(address) {
        bytes32 newSalt = keccak256(abi.encode(_salt, _keys, _backups));
        bytes memory code = abi.encodePacked(type(AccountProxy).creationCode, uint256(accountImpl));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), newSalt, keccak256(code)));
        address account = address(uint160(uint256(hash)));
        return account;
    }

    /**
     * @dev Change logicManager and accountStorage. Called only by owners.
     * @param _mgr The new logic manager.
     * @param _storage The new account storage.
     */
    function setAddresses(address _mgr, address _storage) external onlyMultiOwners {
        logicManager = _mgr;
        accountStorage = _storage;
        emit AddressesSet(_mgr, _storage);
    }
}