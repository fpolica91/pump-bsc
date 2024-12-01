//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";

contract Token is ERC20, Ownable, ReentrancyGuard, ERC165 {
    uint256 initialSupply = 800_000_000 * 10 ** 18;
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {}
    function mint(address to) external onlyOwner {
        _mint(to, initialSupply);
    }
}

contract LiquidityPool is ERC165 {
    IERC20 public token;
    constructor(address _token) {
        token = IERC20(_token);
    }

    function buyTokens(address user) external payable {
        uint256 amount = msg.value;
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens");
        token.transfer(user, amount);
    }

    function sellTokens(uint256 amount) external {
        require(address(this).balance >= amount, "Not enough ETH");
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }
}

contract TokenFactory is ReentrancyGuard, ERC165 {
    event NewTokenPairCreated(address token, address liquidityPool);
    mapping(address => address[]) public userTokens;
    mapping(address => address) public liquidityPools;
    address[] public tokens;
    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        Token token = new Token(name, symbol);
        LiquidityPool lp = new LiquidityPool(address(token));
        token.mint(address(lp));
        emit NewTokenPairCreated(address(token), address(lp));
        userTokens[msg.sender].push(address(token));
        tokens.push(address(token));
        liquidityPools[address(token)] = address(lp);
        return address(token);
    }
    function getLiquidityPool(address token) public view returns (address) {
        return liquidityPools[token];
    }
    function getDeployedTokens(uint256 index) public view returns (address) {
        return tokens[index];
    }
    function getAllTokens() public view returns (address[] memory) {
        return tokens;
    }

    function buyToken(address token) public payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        LiquidityPool lp = LiquidityPool(liquidityPools[token]);
        lp.buyTokens{value: msg.value}(msg.sender);
    }
}
