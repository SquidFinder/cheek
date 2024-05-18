//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Hybrid ERC-404 
// On base, only tradeable on exchanges i.e. uniswap, sushi
// and only available on https://rarible.com/

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./cheekyBasturdWL.sol";
import "./ARC404.sol";


contract CheekyBasturds is ARC404, ERC165, ReentrancyGuard {

    using Strings for uint256;
    
    //Constant
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //Metadata
    string public baseURI;
    string public baseExtension;

    //Royalties
    uint256 public royaltyAmount;
    address public royaltiesAddr;

    //AvailableID settings
    uint256 public arrayFlipAmt;
    uint256 public lastFlipSize;

    // WL Mappings and Arrays
    mapping( address => bool ) public hasMinted;

    //Claim Params
    uint16 private claimChunk;

    bool public arrayFlipEnabled;

    // Events
    event NFTAirdropped(address receiver, uint256 tokenId, uint256 blocktime);
    
    CheekyBasturdsWL private WL;

    //address private constant router = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
    //address private constant router = 0xeaEE7EE68874218c3558b40063c42B82D3E7232a;
    constructor() ARC404("Neat", "Neat", 18, 2598, msg.sender)
    {
          WL = CheekyBasturdsWL(0x7f4D1ECA45F48480C6f766Dc9533C2bf9650270B);
          balanceOf[owner()] = totalSupply - (uint256(WL.wlSupply()) * 1 ether);          
          //allowance[owner()][router] = totalSupply - (uint256(WL.wlSupply()) * 1 ether);

          whitelist[owner()] = true;

          royaltyAmount = 500;
          arrayFlipAmt = 50;
          claimChunk = 50;

          arrayFlipEnabled = true;
          
          royaltiesAddr = owner();
           
          //baseURI = "ipfs://QmUnTojXfeLGdwLMTKFz7LSp863CH18Q3my4AKHU1KC8nr/";
          baseExtension = ".json";
    }



    function airdropTokens() public onlyOwner {
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
                            
                            _mint(WL.seeAddressAtIndex(i), 1);  
                            emit NFTAirdropped(msg.sender, 1, block.timestamp);
                    } else {           
                        continue;
                    }
                }   
    }



    /**
    * @dev is responsbile for setting an `arrayFlipAmt` that does not flip more values than possible in one 
    *       transaction. This value is blockchain blocksize dependent.
    * @dev feature allowing swapping of the first xx amount of items and the last xx amount of items in the array.
    * @notice this feature attempts to overcome the LIFO problem that leaves the First element forever the first elment. 
    * @notice this will allow for purging of the elements in the _availableIds array so that all the NFTs are cycled. 
    */  
    function flipAvailableIDs() public nonReentrant  {
        require(_availableIds.length >= arrayFlipAmt * 2, "Array length must be at double the array flip amount");
        require(arrayFlipEnabled, "Array flip is locked.");
        require(_availableIds.length > lastFlipSize + arrayFlipAmt || _availableIds.length < lastFlipSize - arrayFlipAmt,
            "Available IDs array is still within the range of the last flip. Please try again later.");

        uint256 length = _availableIds.length;
        lastFlipSize = length;

        // Swap the first xx elements with the last xx elements
        for (uint256 i = 0; i < arrayFlipAmt; i++) {
            uint256 temp = _availableIds[i];
            _availableIds[i] = _availableIds[length - arrayFlipAmt + i];
            _availableIds[length - arrayFlipAmt + i] = temp;
        }
    }



    /**
    * @return string containing baseURI + tokenID + baseExtension readable by marketplaces and block explorers
    * @param tokenId is the ID of the NFT that caller seeks metadata URI of
    */ 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "ERC404Metadata: URI query for nonexistent token");    
        string memory currentBaseURI = baseURI;

        return
        bytes(currentBaseURI).length > 0 
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

     
    /**
    * @param _salePrice is the price the NFT is being sold at
    * @return receiver is the address receving the royalties
    * @return amount is the amount of royalties that receiver receives
    * @dev when implementing, compiler issues warning for _tokenId, ignore this warning 
    *       _tokenId is required input on multiple marketplaces as of 05/18/24 
    */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 amount) {
        return (royaltiesAddr, ((_salePrice * royaltyAmount) / 10000));
    }

    /**
    * @dev See {ERC165-supportsInterface}.
    * @return Whether the contract supports the given interface.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return 
        interfaceId == type(IERC721).interfaceId || 
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == _INTERFACE_ID_ERC2981 ||
        super.supportsInterface(interfaceId);
    }

    // OWNER
    
    /**
    * @dev set the index count value of items flipped in _availabileIDs
    * @dev setting the flipAmt to a value large than half of the maximum supply will prvent public callers from using the flipAvailableIDs function
    *       at which point the contract will operate on the LIFO that the underlying 404 import is built upon.
    * @notice this is extremely gas intensive and the value is capped at some value largely dependent on the blockchain being used. 
    */
    function setArrayFlipAmt(uint256 flipAmt) public onlyOwner {
        arrayFlipAmt = flipAmt;
    }

    /**
    *@dev allow for locking and unlocking of array flip function.
    */
    function setArrayFlipLock() public onlyOwner {
        arrayFlipEnabled ? arrayFlipEnabled = false : arrayFlipEnabled = true;
    }

    /**
    * @dev sets royalties receiver address
    * @param _royaltiesAddr is the address to which royalties are sent.
    */
    function setRoyaltiesAddr(address _royaltiesAddr) public onlyOwner {
        royaltiesAddr = _royaltiesAddr;
    }

    /**
    * @dev sets royalties on contracts which work with ERC165 
    * @param _royaltyAmount is the precentage of sells that goes to royalties address
    * @dev `500` is 5%
    */
    function setRoyaltyAmount(uint256 _royaltyAmount) public onlyOwner {
        royaltyAmount = _royaltyAmount;
    }

    /**
    * @dev sets base URI for the NFT metadata 
    * @param _baseURI is the ipfs or equal pointer to the metadata folder
    */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    
    /**
    * @dev sets base URI extension for the NFT metadata
    * @param _newBaseExtension is the json or equal format that is readable by marketplaces and block explorers
    */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /**
    * @dev allows for updating wlAddress.
    * @notice does not effect total amount mintable
    * @param wlAddress is cheekBasturdWL contract address
    */
    function setWLAddr(address wlAddress) public onlyOwner {
        WL = CheekyBasturdsWL(wlAddress); 
    }

}
