pragma solidity ^0.4.23;

import './ERC721Token.sol';

contract StarNotary is ERC721Token { 
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }

    struct Coordinates {
        string dec;
        string mag;
        string ra;
    }
    struct Star { 
        string name;
        string story;
        Coordinates coordinates;
        bytes32 coordinatesHash;
    }
    
    // Maps a TokenID to a specific star (allowing us to use that ID as the star'sID)
    mapping(uint256 => Star) public tokenIdToStarInfo;

    // Maps a certain TokenID(starID) to a sale price in ETH
    mapping(uint256 => uint256) public starsForSale;
    
    // Maps a coordinateHash to a boolean (allowing us to check if it exists or not)
    mapping(bytes32 => bool) public starCoordinates;

    // Creates a new Star (struct), and maps it to a TokenID before minting the token.
    function createStar(string _name, uint256 _tokenId, string _dec, string _mag, string _ra, string _story) public { 
        Star memory newStar;
        newStar.name = _name;
        newStar.story = _story;
        newStar.coordinates.dec = _dec;
        newStar.coordinates.mag = _mag;
        newStar.coordinates.ra = _ra;
        // Create unique hash to represent the coordinates.
        newStar.coordinatesHash = sha256(abi.encodePacked(_dec,_mag,_ra));
        
        // Make sure this coordinate combination gets registered
        starCoordinates[newStar.coordinatesHash] = true;

        tokenIdToStarInfo[_tokenId] = newStar;

        ERC721Token.mint(_tokenId);
    }
    
    // Check if the star already exists
    function checkIfStarExists(string _dec, string _mag, string _ra) public view returns (bool _existence) {
        if(!starCoordinates[sha256(abi.encodePacked(_dec,_mag,_ra))]) {
            return(false);
        } else {
            return(true);
        }
    }

    // Allows a Star owner to put the token up for sale.
    function putStarUpForSale(uint256 _tokenId, uint256 _price) public { 
        require(this.ownerOf(_tokenId) == msg.sender);

        starsForSale[_tokenId] = _price;
    }

    // Allows somebody to buy a star if the sale price is set ( > 0 ) 
    function buyStar(uint256 _tokenId) public payable { 
        //Require that the star is for sale.
        require(starsForSale[_tokenId] > 0);

        //Set the starCost as a variable and the original owner's address as a variable
        uint256 starCost = starsForSale[_tokenId];
        address starOwner = this.ownerOf(_tokenId);

        // Require that the msg.value (e.g. price offered) is higher than or equal to the price of the star
        require(msg.value >= starCost);

        // Clear star states
        clearPreviousStarState(_tokenId);

        // Changes that address associated with the TokenID while lowering the balance of the buyer
        transferFromHelper(starOwner, msg.sender, _tokenId);

        // Return change
        if(msg.value > starCost) { 
            msg.sender.transfer(msg.value - starCost);
        }

        // Increase the balance of the "previous" owner by the starCost.
        starOwner.transfer(starCost);
    }

    function clearPreviousStarState(uint256 _tokenId) private {
        //clear approvals 
        tokenToApproved[_tokenId] = address(0);

        //clear being on sale 
        starsForSale[_tokenId] = 0;
    }
    
    // Get star information using a tokenID 
    function tokenIdToStarInfo(uint256 _tokenId) public view returns (string _name, string _story, string _ra, string _dec, string _mag) {
        Star memory theStar = tokenIdToStarInfo[_tokenId];
        return(theStar.name, theStar.story, theStar.coordinates.ra, theStar.coordinates.dec, theStar.coordinates.mag);
    }

    function getOwner(uint256 _tokenId) public view returns (address _owner) {
        return tokenToOwner[_tokenId];
    }

}