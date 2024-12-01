//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Token is
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165
{
    uint256 public constant INITIAL_SUPPLY = 800_000_000 * 10 ** 18;

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
    }
    function mint(address to) external onlyOwner {
        _mint(to, INITIAL_SUPPLY);
    }
}

contract LiquidityPool {
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
    address public tokenImplementation;

    constructor() {
        tokenImplementation = address(new Token());
    }
    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        address clone = Clones.clone(tokenImplementation);
        Token(clone).initialize(name, symbol);
        LiquidityPool lp = new LiquidityPool(address(clone));
        Token(clone).mint(address(lp));
        emit NewTokenPairCreated(clone, address(lp));
        userTokens[msg.sender].push(clone);
        tokens.push(clone);
        liquidityPools[clone] = address(lp);
        return clone;
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
