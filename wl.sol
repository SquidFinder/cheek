//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract CheekyBasturdsWL is AccessControl{

    
    // WL settings (airdrops) 
    uint8 private _chunk;

    uint16 public constant wlSupply = 471;
    uint16 public wlIndex;
    uint16 public airdropIndex;


    // WL Mappings and Arrays
    address[] public whiteListedAddresses;
    
    //mapping( address => uint256 ) public amountToClaim;

    // Access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    error CallerNotMinter(address caller); 
    
    constructor() {
          _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
          grantMinter(msg.sender);

          wlIndex = 0;
          _chunk = 75;
    }

    /**
    * @param _wlAddresses is the array of addresses that are being whitelisted
    * @dev this allows creating a boolean mapping of whitelisted addresses 
    */
    function createWL(address[] calldata _wlAddresses, uint256 chunk) public onlyRole(MINTER_ROLE) {
        require(chunk <= _chunk, "Input chunk size to large.");
        require(whiteListedAddresses.length < wlSupply, "Whitelist is already complete.");
        
    
        for (uint16 i = 0; i < chunk; i++) {
            whiteListedAddresses.push(_wlAddresses[i]);
            wlIndex++;
            //amountToClaim[_wlAddresses[i]] +=1;
        }
    }


    function incrementAirdropCounter() public onlyRole(MINTER_ROLE) {
        require(airdropIndex < getWhitelistedAddressCount(), "Airdrop complete.");
        airdropIndex ++;
    }

    /**
    * @return the total number of whitelisted addresses
    */

    function getWhitelistedAddressCount() public view returns (uint256) {
        return whiteListedAddresses.length;
    }
    

    /** 
    * @return is an array of whitelisted addresses
    */
    function seeWhitelistedAddresses() public view returns (address[] memory) {
        return whiteListedAddresses;
    }

    function seeAddressAtIndex(uint256 index) public view returns (address) {
        return whiteListedAddresses[index];
    }
    

    /**
    * @param minter is hot wallet in control of minting airdrops. 
    */ 
    function grantMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
        airdropIndex = 0;
    }


    /**
    * @param minter is hot wallet in control of minting until max supply is met. 
    */
    function revokeMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }

    /**
    * @param chunk is the maximum value of loop attempts 
    *       the roll call will attempt in one transaction
    */
    function setChunk(uint8 chunk) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _chunk = chunk;
    }

}
