pragma solidity ^0.8.0;

//interface for cross contract call.
//i Know openzeppelin provide us with this interface but there's no fun in using it right. hehehhe..
interface ERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
}

// the final boss of this file
contract TokenICO {
    address public owner;
    address public tokenAddress;
    uint256 public tokenSalePrice;
    uint256 public soldTokens;

    //acts as middle in solidity(in this contract there are some function that can only be called by the owner).
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only Contract Owner can perform this action"
        );
        _;
    }

    //in contructor we are defining the person who is deploying the contarct is the owner.
    constructor() {
        owner = msg.sender;
    }

    //function to update the the new token address.
    function updateTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    //owner can also update the token sales price.
    function updateTokenSalePrice(uint256 _tokenSalePrice) public onlyOwner {
        tokenSalePrice = _tokenSalePrice;
    }

    //you can visualize the mathmatical operation here as like :-
    //Step 1: z=x*y;
    //step 2: z=z/y;
    //step 3: z==x checking if z==x or not.
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    //now you need to buy some token right.well i got you sir.
    function buyToken(uint256 _tokenAmount) public payable {
        //checking if user provided us enough ether
        require(
            msg.value == multiply(_tokenAmount, tokenSalePrice),
            "Insufficient Ether Provided for the token purchase"
        );

        // checking if this ICO contract have enough token or not
        ERC20 token = ERC20(tokenAddress);
        require(
            _tokenAmount <= token.balanceOf(address(this)),
            "Insufficient Token"
        );

        //now lets transfer the token
        require(token.transfer(msg.sender, _tokenAmount * 1e18));

        //Transferring received etherium to the owner
        payable(owner).transfer(msg.value);

        soldTokens += _tokenAmount;
    }

    // function that will give you details about token
    function getTokenDetails()
        public
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 balance,
            uint256 supply,
            uint256 tokenPrice,
            address tokenAddres
        )
    {
        ERC20 token = ERC20(tokenAddress);

        return (
            token.name(),
            token.symbol(),
            token.balanceOf(address(this)),
            token.totalSupply(),
            tokenSalePrice,
            tokenAddress
        );
    }

   

    //our owner can withdraw all the token that exists in all the pool
    function withdrawAllToken() public onlyOwner {
        ERC20 token = ERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "There's no token left");
        require(token.transfer(owner, balance));
    }
}
