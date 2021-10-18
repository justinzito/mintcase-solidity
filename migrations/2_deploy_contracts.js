
const UserDataPool = artifacts.require("UserDataPool");
const CreatorController = artifacts.require("CreatorController");
const SeriesController = artifacts.require("SeriesController");
const MintController = artifacts.require("MintController");
const PaymentController = artifacts.require("PaymentController");


module.exports = async function(deployer) {

  var tokenSymbol = "MNTCSE0";
  var tokenName = "Mintcase Season Zero";
  let treasuryAddress = "0xE1Cc413C6D6B2f2D6ac781159Aa3c92fEd79161E";

  await deployer.deploy(UserDataPool);
  let userDataPool = await UserDataPool.deployed();
  await deployer.deploy(CreatorController,userDataPool.address);
  let creatorController = await CreatorController.deployed();
  await deployer.deploy(SeriesController,userDataPool.address);
  let seriesController = await SeriesController.deployed();
  await deployer.deploy(MintController,userDataPool.address, seriesController.address,tokenSymbol,tokenName);
  let mintController = await MintController.deployed();
  await deployer.deploy(PaymentController,userDataPool.address,mintController.address, treasuryAddress);
  let paymentController = await PaymentController.deployed();

  let proxy_role = "0x77d72916e966418e6dc58a19999ae9934bef3f749f1547cde0a86e809f19c89b";

  await userDataPool.grantRole(proxy_role,creatorController.address);
  await userDataPool.grantRole(proxy_role,seriesController.address);
  await userDataPool.grantRole(proxy_role,paymentController.address);
  await userDataPool.grantRole(proxy_role,mintController.address);
  
};
