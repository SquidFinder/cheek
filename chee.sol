//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Hybrid ERC-404 
// On base, only tradeable on exchanges i.e. uniswap, sushi
// and only available on https://rarible.com/

import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC404.sol";

interface IJoeFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract CheekyBasturds is ERC404, ERC165 {
    
    //Constant
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //Royalties
    uint256 public royaltyAmount;
    address public royaltiesAddr;
    
    //Once trading is enabled, it cannot be undone.  See `enableTrading`.
    bool private tradingEnabled;

    //Router address is used for whitelisting, which allows for liquidity addition to occur in bulk, otherwise adding liquidity
    //      will cost huge amounts of gas 
    address private constant ROUTERADDRESS = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
    address private constant FACTORYADDRESS = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
    address private constant WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c; 
    
    IJoeFactory private _joeFactory = IJoeFactory(0xF5c7d9733e5f53abCC1695820c4818C59B457C2C);

    constructor(address _airdropper) ERC404(msg.sender)
    {
          allowance[msg.sender][_airdropper] = 471 * 1 ether;
          royaltyAmount = 500;
          royaltiesAddr = msg.sender;
          tradingEnabled = false;
//          setWhitelist(routerAddress, true);  
          //setWhitelist(FACTORYADDRESS, true);
          _createNewPairing(WAVAX, address(this));
          setWhitelist(getPair(), true);
          allowance[msg.sender][ROUTERADDRESS];
    }

    /**
    * @return pair returns address of joe factory LP 
    */
    function getPair() public view returns (address pair) {
        return _joeFactory.getPair(WAVAX, address(this));
    }

    /**
    * @param _tokenA, _tokenB is CoqInu and his address in any order.  Could also be this address and wavax.
    */
    function _createNewPairing(address _tokenA, address _tokenB) internal {
        address pairAddr = getPair();
        if(pairAddr == address(0)) {
            _joeFactory.createPair(_tokenA, _tokenB);
        }
    }

    /**
    * @dev allows enabling trading one time and then function no longer operates
    */
    function enableTrading() public onlyOwner() {
        require(tradingEnabled, "Trading is already enabled.");
        if ( !(tradingEnabled) ) { 
            tradingEnabled = true;
        }
    }

    /** 
    * @notice because adding liquidity on ERC404s is gas intensive, we can only add ~400-500 at a time depending on the chain
    *       because of this restriction we need trading to be disabled until initial liquidity addition is complete.
    * @dev considering the airdrop needs to be complete, this also allows trading to be disabled until airdrop is complete
    * @dev for params see _transfer in `ERC404`  
    */
    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if ( !(tradingEnabled) ) { // still waiting for liquidity to added and trading to be enabled
      require(from == owner || to == owner, "Cannot transfer until mint enters public.");
      return;
    }
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
        interfaceId == _INTERFACE_ID_ERC2981 ||
        super.supportsInterface(interfaceId);
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
}

