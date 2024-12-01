//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Token is ERC20, Ownable, ReentrancyGuard {
    uint256 initialSupply = 800_000_000;
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {}
    function mint(address to) external onlyOwner {
        _mint(to, initialSupply);
    }
}

contract LiquidityPool {
    IERC20 public token;
    constructor(address _token) {
        token = IERC20(_token);
    }

    function buyTokens() external payable {
        uint256 amount = msg.value;
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens");
        token.transfer(msg.sender, amount);
    }

    function sellTokens(uint256 amount) external {
        require(address(this).balance >= amount, "Not enough ETH");
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }
}

contract TokenFactory is ReentrancyGuard {
    event NewTokenPairCreated(address token, address liquidityPool);
    mapping(address => address[]) public userTokens;
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
        return address(token);
    }
    function getDeployedTokens(uint256 index) public view returns (address) {
        return tokens[index];
    }
    function getAllTokens() public view returns (address[] memory) {
        return tokens;
    }
}
