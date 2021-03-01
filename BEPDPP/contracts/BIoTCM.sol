pragma solidity >=0.4.22 <0.8.0;

contract BIoTCM {
    
    struct ContentProduct{
        uint id;
        string description;
        uint[] price;
        uint[] boundedError;
        mapping(address=>bool) accessList;
        mapping(address=>string) ContentProductHash;
        address payable owner;
    }
    
    struct Consumer {
        string publicKey;
    }
    
    address public contractCreator;
    uint public ContentProductCount = 0;
    mapping(uint => ContentProduct) private ContentProducts;
    mapping(address => Consumer) private ConsumerMap;
    
     constructor () public {
        contractCreator = msg.sender;
    }
    
    event ContentProductCreated(uint id, string  description, uint[] price, uint[] boundedError ,address owner);
    event ConsumerRegisterProductEvent(address Consumer , string message);
    event ProductContentPurchased(uint id, string description, uint price , uint boundedError , address payable owner, address Consumer,string ConsumerPubliceKey);
    event ProductContentSend(uint id,address owner,address Consumer);
    event ProductContentQuery(string fileHash);
    
    function dataOwnerCreateContentProduct(string  memory _description, uint[] memory _price, uint[] memory _boundedError) public{
        // Increment ContentProduct Count
        ContentProductCount++;
        // Create the ContentProduct
        ContentProducts[ContentProductCount].id = ContentProductCount;
        ContentProducts[ContentProductCount].description = _description;
        ContentProducts[ContentProductCount].price = _price;
        ContentProducts[ContentProductCount].boundedError = _boundedError;
        ContentProducts[ContentProductCount].owner = msg.sender;
        emit ContentProductCreated(ContentProductCount,_description,_price,_boundedError,msg.sender);
    }
    
    function consumerRegisterProduct (string memory _publicKey) public returns (address) {
        // check if consumer is already registered
        require(bytes(ConsumerMap[msg.sender].publicKey).length == 0,"Consumer Already Registered");
        ConsumerMap[msg.sender].publicKey = _publicKey;
        emit ConsumerRegisterProductEvent(msg.sender,"Sucessfully Registered");
        return msg.sender;
    }
    
    function purchaseProductContent(uint _id) public payable{
        ContentProduct storage _product = ContentProducts[_id];
        uint _boundedError;
        for (uint it =0 ; it < _product.price.length; it++ ){
            if (_product.price[it] == msg.value ){
                _product.accessList[msg.sender] = true;
                _boundedError = _product.boundedError[it];
            }
        }
        if (_product.accessList[msg.sender] == true){
            address payable _owner = _product.owner;
            payable(_owner).transfer(msg.value);
            emit ProductContentPurchased(_id,_product.description,msg.value,_boundedError,_owner,msg.sender,ConsumerMap[msg.sender].publicKey);
        }
        else{
            revert();
        }
    }

    function sendProductContent(uint _id, string memory _fileHash, address _Consumer) public {
        ContentProducts[_id].ContentProductHash[_Consumer] = _fileHash;
        emit ProductContentSend(_id,msg.sender,_Consumer);
    }
    
    function queryProductContent(uint _id) public {
        ContentProduct storage _product = ContentProducts[_id];
        if (_product.accessList[msg.sender] == true) {
            emit ProductContentQuery(_product.ContentProductHash[msg.sender]);
        }
        else{
            revert();
        }
    }
    
    function getProductInfo(uint _id) public view returns (uint id, string memory, uint[] memory , uint[] memory, address){
        return (ContentProducts[_id].id,ContentProducts[_id].description,ContentProducts[_id].price,ContentProducts[_id].boundedError,ContentProducts[_id].owner);
    }
    
}