pragma solidity ^0.4.25;

import "./ERC721XToken.sol";

contract ZombieCard is ERC721XToken {
   
    mapping(uint => uint) internal tokenIdToIndividualSupply;
    // map to see the nftTokenId count from FT
    mapping(uint => uint) internal nftTokenIdToMouldId;
    uint nftTokenIdIndex = 1000000;

    event TokenAwarded(uint indexed tokenId, address claimer, uint amount);

    
    function name() external view returns (string) {
        return "ZombieCard";
    }

    
    function symbol() external view returns (string) {
        return "ZCX";
    }

    
    function individualSupply(uint _tokenId) public view returns (uint) {
        return tokenIdToIndividualSupply(_tokenId);
    }

    
    function batchMintTokens(uin[] _tokenIds, uint[] _tokenSupplies) external onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            mintToken(_tokenIds[i], _tokenSupplies[i]);
        }
    }

    // minting tokens for the cards
    function mintToken(uint _tokenId, uint _supply) public onlyOwner {
        require(!exists(_tokenId), "Error: Tried to mint duplicate token id");
        _mint(_tokenId, msg.sender, _supply);
        tokenIdToIndividualSupply[_tokenId] = _supply;
    }

    // awarding tokens to _to from the msg.sender
    function awardToken(uint _tokenId, address _to, uint _amount) public onlyOwner {
        require(exists(_tokenId), "TokenID has not been minted");
        if (individualSupply[_tokenId] > 0) {
            require(_amount <= balanceOf(msg.sender, _tokenId), "Quantity greater than remaining cards");
            // _updateTokenBalance is from ERC721XToken
            _updateTokenBalance(msg.sender, _tokenId, _amount, ObjectLib.Operations.SUB);
        }
        _updateTokenBalance(_to, _tokenId, _amount, ObjectLib.Operations.ADD);
        emit TokenAwarded(_tokenId, _to, _amount);
    }

    // coverting Fungible Tokens to Non Fungible Tokens
    function convertToNFT(uint _tokenId, uint _amount) public {
        require(tokenType[_tokenId] == FT);
        require(_amount <= balanceOf(msg.sender, _tokenId), "You do not own enough tokens");
        
        _updateTokenBalance(msg.sender, _tokenId, _amount, ObjectLib.Operations.SUB);
        for (uint i = 0; i < _amount; i++) {
             _mint(nftTokenIdIndex, msg.sender);
            nftTokenIdToMouldId[nftTokenIdIndex] = _tokenId;
            nftTokenIdIndex++;
        }
    }

    // converting Non-fungible tokens to fungible tokens
    function convertToFT(uint _tokenId) public {
        require(tokenType[_tokenId] == NFT);
        require(ownerOf(_tokenId) == msg.sender, "You do not own this token");
        _updateTokenBalance(msg.sender, _tokenId, 0, ObjectLib.Operations.REPLACE);
        _updateTokenBalance(msg.sender, nftTokenIdToMouldId[_tokenId], 1, ObjectLib.Operations.ADD);
        emit TransferWithQuantity(address(this), msg.sender, nftTokenIdToMouldId[_tokenId], 1);
    }

}

