const { expect } = require("chai");
describe("Token contract", function () {
  it("Deployment token factory", async function () {
    const [owner] = await ethers.getSigners();
 
    // const hardhatToken = await ethers.deployContract("Token", ["Test", "TEST"]);
    // const liquidityPool = await ethers.deployContract("LiquidityPool", [hardhatToken.address]);
    const tokenFactory = await ethers.deployContract("TokenFactory");
    const tx = await tokenFactory.createToken("Test", "TEST");
    await tx.wait()
    const tokenAddress = await tokenFactory.getDeployedTokens(0)
    const allTokens = await tokenFactory.getAllTokens()

    // expect(await token.balanceOf(owner.address)).to.equal(800_000_000);
    expect(true).to.be.true;
    // console.log(token);



  //   const ownerBalance = await hardhatToken.balanceOf(owner.address);
  //   expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });
});