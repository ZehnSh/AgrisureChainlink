const { expect } = require("chai");

describe("Token contract", function () {
  let hardhatToken;

  beforeEach(async()=>{
    const Token = await ethers.getContractFactory("insuranceRegistery");
    hardhatToken = await Token.deploy();
    await hardhatToken.deployed();
  })

  it("Deployment should assign the total supply of tokens to the owner", async  ()=> {
    const [owner,addr1,addr2] = await ethers.getSigners();
    // console.log(addr1.address)
    // let data=await hardhatToken.InsuranceId();
    // console.log("data",data.toNumber());
    let insuranceId=await hardhatToken.insuranceRegister([owner.address,1234,2345,12,12345,123,123,"rrr",12,"hiiiih","hhh",123]);
    console.log(insuranceId);
  });
});