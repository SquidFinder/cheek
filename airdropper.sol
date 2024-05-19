//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Hybrid ERC-404 
// On base, tradeable on exchanges i.e. uniswap, sushi
// and NFT marketplaces Opensea, among others. 

import "./cheekyBasturdsWL.sol";
import "./ERC404.sol";

contract Airdropper is AccessControl{

    ERC404 public ERC404Contract = ERC404(0xBc7ee590101bd92f8073CFBF789313Cd59011f71);

    // WL Mappings and Arrays
    mapping( address => bool ) public hasMinted;

    //Claim Params
    uint16 private claimChunk;

    // Events
    event NFTAirdropped(address receiver, uint256 tokenId, uint256 blocktime);
    
    CheekyBasturdsWL private WL;
    
    address private tokenHolder;
    uint256 private unitToTx;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    error CallerNotMinter(address caller); 



    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        tokenHolder = msg.sender;
        unitToTx = 1 ether;
    }



    //Testing with param
    function txFrom(address toAddress) public onlyRole(MINTER_ROLE) {
        ERC404Contract.transferFrom(
            tokenHolder, toAddress, 
            1 ether);  
        emit NFTAirdropped(msg.sender, 1, block.timestamp);
    }



    function airdropTokens() public onlyRole(MINTER_ROLE) {
                uint256 wlAddressCount =  WL.getWhitelistedAddressCount();
                uint256 currentAirdropIndex = WL.airdropIndex();
                uint256 chunk = claimChunk;
                
                require((uint256(WL.wlSupply()) - currentAirdropIndex) > 0, "Airdrop complete.");

                if (uint256(WL.wlSupply()) - currentAirdropIndex < claimChunk) {
                    chunk = uint256(WL.wlSupply()) - currentAirdropIndex;
                }

                for (uint256 i = currentAirdropIndex; 
                    i < currentAirdropIndex + chunk && i < wlAddressCount; i++) 
                    {
                        if (hasMinted[WL.seeAddressAtIndex(i)] == false) {
                            hasMinted[WL.seeAddressAtIndex(i)] = true;                
                            WL.incrementAirdropCounter();
                            
                            ERC404Contract.transferFrom(
                                tokenHolder, WL.seeAddressAtIndex(i), 
                                1 ether);  
                            emit NFTAirdropped(msg.sender, 1, block.timestamp);
                    } else {           
                        continue;
                    }
                }   
    }


    /**
    * @dev allows for updating wlAddress.
    * @notice does not effect total amount mintable
    * @param wlAddress is cheekBasturdWL contract address
    */
    function setWLAddr(address wlAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WL = CheekyBasturdsWL(wlAddress); 
    }
}
