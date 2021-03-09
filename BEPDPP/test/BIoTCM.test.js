// BIoTCM Smart Contract Test
const BIoTCM = artifacts.require('./BIoTCM.sol');
const fs = require('fs')
const path = require('path')
const ipfsClient = require('ipfs-http-client')
const ipfs = new ipfsClient({ host: 'ipfs.infura.io', port: 5001, protocol: 'https' }) // leaving out the arguments will default to these values

contract('BIoTCM',([deployer,dataOwner,consumer])=> {

    console.log('deployer address : ' + deployer)
    console.log('dataOwner address : ' + dataOwner)
    console.log('consumer address :' + consumer)

    let bIoTCM;

    before(async()=>{
        bIoTCM = await BIoTCM.deployed(); 
    });

    describe('deployment',async()=>{
        it('deploys successfully', async()=>{
            const address = await bIoTCM.address
            const smartContractOwner = await bIoTCM.contractCreator()
            // console.log('smartContract address : ' + address)
            assert.equal(smartContractOwner,deployer)
            assert.notEqual(address, 0x0)
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
        })
    });

    describe('ContentProduct',async()=>{

        let contentProductCreatedResult
        let consumerRegisterProductResult
        let contentProductCount

        before(async()=>{
            contentProductCreatedResult = await bIoTCM.dataOwnerCreateContentProduct('PM2.5',[web3.utils.toWei('4', 'Ether'),web3.utils.toWei('5', 'Ether'),web3.utils.toWei('6', 'Ether')],[1,2,3],{ from: dataOwner })
            contentProductCount = await bIoTCM.ContentProductCount()
            consumerPulicKey = 'MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJ5BTsx3s1q8d3tln8Fubjt3B9G2pdH+trJ4bDeMf9116FYEzINLpCRqyPDq/MaPWdQ05JCScqbPWyYgiqBHiXcCAwEAAQ=='
            consumerRegisterProductResult = await bIoTCM.consumerRegisterProduct(consumerPulicKey,{ from: consumer })
        });

        it('dataOwner creates contentProduct',async()=>{
            assert.equal(contentProductCount,1)
            // console.log(contentProductCreatedResult)
            const contentProductCreatedEvent = contentProductCreatedResult.logs[0].args
            assert.equal(contentProductCreatedEvent.id.toNumber(), contentProductCount.toNumber(), 'id is not correct')
            assert.equal(contentProductCreatedEvent.description,'PM2.5','Description is not correct')
            assert.equal(contentProductCreatedEvent.price[0].toString(),'4000000000000000000','price is not correct')
            assert.equal(contentProductCreatedEvent.price[1].toString(),'5000000000000000000','price is not correct')
            assert.equal(contentProductCreatedEvent.price[2].toString(),'6000000000000000000','price is not correct')
            assert.equal(contentProductCreatedEvent.boundedError[0],'1','boundedError is not correct')
            assert.equal(contentProductCreatedEvent.boundedError[1],'2','boundedError is not correct')
            assert.equal(contentProductCreatedEvent.boundedError[2],'3','boundedError is not correct')
            assert.equal(contentProductCreatedEvent.owner,dataOwner,'DataOwner is not correct' )
        });

        it('consumer Register Product',async()=>{
            // console.log(consumerRegisterProductResult)
            const consumerRegisterProductEvent = consumerRegisterProductResult.logs[0].args
            // console.log(consumerRegisterProductEvent)
            assert.equal(consumerRegisterProductEvent.Consumer,consumer,'consumer is not Register')
        });

        it('list Product Information',async()=>{
            const getProductInfoResult = await bIoTCM.getProductInfo(contentProductCount)
            // console.log(getProductInfoResult)
            assert.equal(getProductInfoResult[0].toNumber(), contentProductCount.toNumber(), 'id is not correct')
            assert.equal(getProductInfoResult[1],'PM2.5','Description is not correct')

            assert.equal(getProductInfoResult[2][0].toString(),'4000000000000000000','price is not correct')
            assert.equal(getProductInfoResult[2][1].toString(),'5000000000000000000','price is not correct')
            assert.equal(getProductInfoResult[2][2].toString(),'6000000000000000000','price is not correct')

            assert.equal(getProductInfoResult[3][0],'1','boundedError is not correct')
            assert.equal(getProductInfoResult[3][1],'2','boundedError is not correct')
            assert.equal(getProductInfoResult[3][2],'3','boundedError is not correct')
        });

        it('purchase ProductContent',async()=>{
            // Track the dataOwner balance before purchase
            let oldDataOwnerBalance
            oldDataOwnerBalance = await web3.eth.getBalance(dataOwner)
            oldDataOwnerBalance = new web3.utils.BN(oldDataOwnerBalance)

            const purchaseProductContentResult = await bIoTCM.purchaseProductContent(contentProductCount,{ from: consumer, value: web3.utils.toWei('5', 'Ether')})
            // console.log(purchaseProductContentResult)
            const productContentPurchasedEvent = purchaseProductContentResult.logs[0].args
            // console.log(productContentPurchasedEvent)
            assert.equal(productContentPurchasedEvent.id.toNumber(),contentProductCount.toNumber(),'id is not correct')
            assert.equal(productContentPurchasedEvent.description,'PM2.5','Description is not correct') 
            assert.equal(productContentPurchasedEvent.price.toString(),'5000000000000000000','price is not correct')
            assert.equal(productContentPurchasedEvent.boundedError,'2','boundedError is not correct')
            assert.equal(productContentPurchasedEvent.owner,dataOwner,'DataOwner is not correct')
            assert.equal(productContentPurchasedEvent.Consumer,consumer,'consumer is not correct')
            assert.equal(productContentPurchasedEvent.ConsumerPubliceKey,'MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJ5BTsx3s1q8d3tln8Fubjt3B9G2pdH+trJ4bDeMf9116FYEzINLpCRqyPDq/MaPWdQ05JCScqbPWyYgiqBHiXcCAwEAAQ==','consumerPubliceKey is not correct')

            // Check that dataOwner received funds
            let newDataOwnerBalance
            newDataOwnerBalance = await web3.eth.getBalance(dataOwner)
            newDataOwnerBalance = new web3.utils.BN(newDataOwnerBalance)

            let price
            price = web3.utils.toWei('5', 'Ether')
            price = new web3.utils.BN(price)
            const exepectedBalance = oldDataOwnerBalance.add(price)
            assert.equal(newDataOwnerBalance.toString(), exepectedBalance.toString())
        });

        it('send ProductContent',async()=>{

            var buffer = fs.readFileSync(path.resolve('../BEPDPP/dataset/Temperature.csv'))
            // console.log(buffer)
            const productContentAdded = await ipfs.add(buffer);
            const productContentHash = productContentAdded.path

            // console.log("productContentHash : " + productContentHash);
            // console.log('https://ipfs.infura.io/ipfs/'+productContentHash)

            const sendProductContentResult =  await bIoTCM.sendProductContent(contentProductCount,productContentHash,consumer,{from:dataOwner}) 
            // console.log(sendProductContentResult)
            const productContentSendEvent = sendProductContentResult.logs[0].args
            // console.log(productContentSendEvent)
            assert.equal(productContentSendEvent.id.toNumber(),contentProductCount.toNumber(),'id is not correct')
            assert.equal(productContentSendEvent.owner,dataOwner,'DataOwner is not correct')
            assert.equal(productContentSendEvent.Consumer,consumer,'consumer is not correct')    
        })

        it('query ProductContent',async()=>{
            const queryProductContentResult = await bIoTCM.queryProductContent(contentProductCount,{from:consumer})
            // console.log(queryProductContentResult)
            const productContentQueryEvent = queryProductContentResult.logs[0].args
            // console.log(productContentQueryEvent)
            assert.equal(productContentQueryEvent.fileHash,"QmdSP2rbRtyqEEKSHQojBZfdWEehm1Pmt2rV7vSaHTXCpT",'fileHash is not correct')
        })
    });
});