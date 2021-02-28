pragma solidity >=0.4.22 <0.8.0;

contract BEDMoB {
    
    struct ContentProduct{
        uint id;
        string description;
        uint[] price;
        uint[] boundedError;
        mapping(address=>bool) accessList;
        mapping(address=>string) ContentProductHash;
        address payable owner;
    }
    
    struct Customer {
        string publicKey;
    }
    
    address public contractCreator;
    uint public ContentProductCount = 0;
    mapping(uint => ContentProduct) private ContentProducts;
    mapping(address => Customer) private CustomerMap;
    
     constructor () public {
        contractCreator = msg.sender;
    }
    
    event ContentProductCreated(uint id, string  description, uint[] price, uint[] boundedError ,address owner);
    event CustomerRegisterProductEvent(address Customer , string message);
    event ContentProductPurchased(uint id, string description, uint price , uint boundedError , address payable owner, address Customer,string CustomerPubliceKey);
    event ContentProductSend(uint id,address owner,address Customer);
    event ContentProductQuery(string fileHash);
    
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
    
    function customerRegisterProduct (string memory _publicKey) public returns (address) {
        // check if customer is already registered
        require(bytes(CustomerMap[msg.sender].publicKey).length == 0,"Customer Already Registered");
        CustomerMap[msg.sender].publicKey = _publicKey;
        emit CustomerRegisterProductEvent(msg.sender,"Sucessfully Registered");
        return msg.sender;
    }
    
    function purchaseContentProduct(uint _id) public payable{
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
            emit ContentProductPurchased(_id,_product.description,msg.value,_boundedError,_owner,msg.sender,CustomerMap[msg.sender].publicKey);
        }
        else{
            revert();
        }
    }

    function sendContentProduct(uint _id, string memory _fileHash, address _Customer) public {
        ContentProducts[_id].ContentProductHash[_Customer] = _fileHash;
        emit ContentProductSend(_id,msg.sender,_Customer);
    }
    
    function queryContentProduct(uint _id) public {
        ContentProduct storage _product = ContentProducts[_id];
        if (_product.accessList[msg.sender] == true) {
            emit ContentProductQuery(_product.ContentProductHash[msg.sender]);
        }
        else{
            revert();
        }
    }
    
    function getContentProductInfo(uint _id) public view returns (uint id, string memory, uint[] memory , uint[] memory, address){
        return (ContentProducts[_id].id,ContentProducts[_id].description,ContentProducts[_id].price,ContentProducts[_id].boundedError,ContentProducts[_id].owner);
    }
    
}