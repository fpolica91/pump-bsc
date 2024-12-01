const { expect } = require("chai");
describe("Token contract", function () {
  it("Deployment token factory", async function () {
    const tokenFactory = await ethers.deployContract("TokenFactory");
    const tx = await tokenFactory.createToken("Test", "TEST");
    await tx.wait()
    const tokenAddress = await tokenFactory.getDeployedTokens(0)
    const token = await ethers.getContractAt("Token", tokenAddress)
    const liquidityPoolAddress = await tokenFactory.getLiquidityPool(tokenAddress)
    await ethers.getContractAt("LiquidityPool", liquidityPoolAddress)
    const balance = await token.balanceOf(liquidityPoolAddress)
    expect(balance).to.equal(BigInt(800_000_000) * BigInt(10 ** 18))
    await tokenFactory.buyToken(tokenAddress, { value: ethers.parseEther("1.0") });
    expect(await token.balanceOf(liquidityPoolAddress)).to.equal(BigInt(799_999_999) * BigInt(10 ** 18))
  });
});