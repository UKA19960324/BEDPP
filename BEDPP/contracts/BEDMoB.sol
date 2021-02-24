pragma solidity >=0.4.22 <0.8.0;

contract BEDMoB {
    
    struct IoTDataProduct{
        uint id;
        string description;
        uint[] price;
        uint[] boundedError;
        mapping(address=>bool) accessList;
        mapping(address=>string) IoTDataProductHash;
        address payable owner;
    }
    
    struct Customer {
        string publicKey;
    }
    
    address public contractCreator;
    uint public IoTDataProductCount = 0;
    mapping(uint => IoTDataProduct) private IoTDataProducts;
    mapping(address => Customer) private CustomerMap;
    
     constructor () public {
        contractCreator = msg.sender;
    }
    
    event IoTDataProductCreated(uint id, string  description, uint[] price, uint[] boundedError ,address owner);
    event CustomerRegisterEvent(address Customer , string message);
    event IoTDataProductPurchased(uint id, string description, uint price , uint boundedError , address payable owner, address Customer,string CustomerPubliceKey);
    event IoTDataProductSend(uint id,address owner,address Customer);
    event IoTDataProductQuery(string fileHash);
    
    function createIoTDataProduct(string  memory _description, uint[] memory _price, uint[] memory _boundedError) public{
        // Increment IoTDataProduct count
        IoTDataProductCount++;
        // Create the IoTDataProduct
        IoTDataProducts[IoTDataProductCount].id = IoTDataProductCount;
        IoTDataProducts[IoTDataProductCount].description = _description;
        IoTDataProducts[IoTDataProductCount].price = _price;
        IoTDataProducts[IoTDataProductCount].boundedError = _boundedError;
    
        IoTDataProducts[IoTDataProductCount].owner = msg.sender;
        emit IoTDataProductCreated(IoTDataProductCount,_description,_price,_boundedError,msg.sender);
    }
    
    function CustomerRegister (string memory _publicKey) public returns (address) {
        // check if customer is already registered
        require(bytes(CustomerMap[msg.sender].publicKey).length == 0,"Customer Already Registered");
        CustomerMap[msg.sender].publicKey = _publicKey;
        emit CustomerRegisterEvent(msg.sender,"Sucessfully Registered");
        return msg.sender;
    }
    
    function purchaseIoTDataProduct(uint _id) public payable{
        IoTDataProduct storage _product = IoTDataProducts[_id];
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
            emit IoTDataProductPurchased(_id,_product.description,msg.value,_boundedError,_owner,msg.sender,CustomerMap[msg.sender].publicKey);
        }
        else{
            revert();
        }
    }

    function sendIoTdataProduct(uint _id, string memory _fileHash, address _Customer) public {
        IoTDataProducts[_id].IoTDataProductHash[_Customer] = _fileHash;
        emit IoTDataProductSend(_id,msg.sender,_Customer);
    }
    
    function queryIoTdataProduct(uint _id) public {
        IoTDataProduct storage _product = IoTDataProducts[_id];
        if (_product.accessList[msg.sender] == true) {
            emit IoTDataProductQuery(_product.IoTDataProductHash[msg.sender]);
        }
        else{
            revert();
        }
    }
    
    function getIoTDataProductInfo(uint _id) public view returns (uint id, string memory, uint[] memory , uint[] memory, address){
        return (IoTDataProducts[_id].id,IoTDataProducts[_id].description,IoTDataProducts[_id].price,IoTDataProducts[_id].boundedError,IoTDataProducts[_id].owner);
    }
    
}