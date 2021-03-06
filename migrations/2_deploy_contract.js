const AccountStorage = artifacts.require("AccountStorage");
const AccountLogic = artifacts.require("AccountLogic");
const LogicManager = artifacts.require("LogicManager");
const Account = artifacts.require("Account");
const AccountProxy = artifacts.require("AccountProxy");
const TransferLogic = artifacts.require("TransferLogic");
const AccountCreator = artifacts.require("AccountCreator");
const DualsigsLogic = artifacts.require("DualsigsLogic");
const DappLogic = artifacts.require("DappLogic");
const CommonStaticLogic = artifacts.require("CommonStaticLogic");
const ProposalLogic = artifacts.require("ProposalLogic");

//test
const MyToken = artifacts.require("MyToken");
const MyNft = artifacts.require("MyNft");

module.exports =  async function(deployer) {
    await deployer.deploy(AccountStorage).then(async () => {
        await deployer.deploy(AccountLogic, AccountStorage.address);

        await deployer.deploy(TransferLogic, AccountStorage.address);

        await deployer.deploy(DualsigsLogic, AccountStorage.address);

        await deployer.deploy(DappLogic, AccountStorage.address);

        await deployer.deploy(CommonStaticLogic, AccountStorage.address);

        await deployer.deploy(ProposalLogic, AccountStorage.address);
        
        await deployer.deploy(Account);
        
        await deployer.deploy(LogicManager, [AccountLogic.address, TransferLogic.address, DualsigsLogic.address, DappLogic.address, CommonStaticLogic.address, ProposalLogic.address], 4).then(()=>{
            deployer.deploy(AccountCreator, LogicManager.address, AccountStorage.address, Account.address);
        });

        console.log(`AccountLogic ${AccountLogic.address}, TransferLogic ${TransferLogic.address}, 
                    DualsigsLogic ${DualsigsLogic.address}, DappLogic ${DappLogic.address}, 
                    CommonStaticLogic ${CommonStaticLogic.address}, ProposalLogic ${ProposalLogic.address}, 
                    LogicManager ${LogicManager.address}, Account ${Account.address}`);

        //test
        await deployer.deploy(MyToken, "MyToken", "MTK", 4);
        await deployer.deploy(MyNft);
        
    });

};
