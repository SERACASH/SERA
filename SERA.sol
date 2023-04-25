// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract SERA {
    string public name = "SERA";
    string public symbol = "SERA";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    uint256 public feePool;
    uint256 public feePercentage = 50; // 0.5%
    uint256 public feePoolMinimum = 1 ether; // Minimum fee pool amount required to continue rewards
    address public owner;
    address public mintAddress;
    address public paymentGatewayAddress;
 

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rewardBalanceOf;
    mapping(address => uint256) public lastClaimTime;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardPaid(address indexed user, uint256 reward);
    event Mint(address indexed to, uint256 value);
    event Redeem(address indexed from, uint256 value);
    event Burn(address indexed account, uint256 amount);
    event FeePercentageChanged(uint256 newFeePercentage);
    event FeePoolMinimumChanged(uint256 newFeePoolMinimum);

    constructor(uint256 _initialSupply, address _paymentGatewayAddress) {
    totalSupply = _initialSupply;
    balanceOf[msg.sender] = _initialSupply;
    owner = msg.sender;
    paymentGatewayAddress = _paymentGatewayAddress;
}
 

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
 
        uint256 fee = (_value * feePercentage) / 10000; // calculate fee (0.5%)
        uint256 transferAmount = _value - fee; // calculate transfer amount
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        feePool += fee;
 
        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, address(this), fee);
 
        return true;
    }
 
    function mint(address _to, uint256 _value) public {
        require(msg.sender == owner || msg.sender == paymentGatewayAddress, "Only the contract owner or payment gateway can mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
 
        emit Mint(_to, _value);
    }

   function burn(uint256 _value) public {
    require(balanceOf[msg.sender] >= _value, "Insufficient balance");
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    emit Transfer(msg.sender, address(0), _value);
    emit Burn(msg.sender, _value);
}

    function calculateReward(address _user) public view returns (uint256) {
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[_user];
        uint256 rewardAmount = ((balanceOf[_user] + rewardBalanceOf[_user]) * timeSinceLastClaim) / (2 weeks);
        return rewardAmount;
    }
 
    function reward() public {
        uint256 rewardAmount = calculateReward(msg.sender);
        require(rewardAmount > 0, "No rewards available");
        require(feePool >= feePoolMinimum, "Fee pool below minimum level");
 
        uint256 rewardProportion = (balanceOf[msg.sender] * rewardAmount) / (balanceOf[msg.sender] + rewardBalanceOf[msg.sender]);
        rewardBalanceOf[msg.sender] += rewardProportion;
        feePool -= rewardProportion;
        uint256 ethAmount = rewardProportion / (10 ** decimals); // convert stablecoin amount to Ether
        payable(msg.sender).transfer(ethAmount);
 
        emit RewardPaid(msg.sender, ethAmount);
    }
 
    function withdrawFees() public {
        require(msg.sender == owner, "Only the contract owner can withdraw fees");
        require(feePool >= feePoolMinimum, "Fee pool below minimum level");
 
        uint256 totalStablecoin = totalSupply - balanceOf[address(this)]; // calculate total stablecoin supply excluding fee pool
        uint256 userBalance = balanceOf[msg.sender];
        require(userBalance > 0, "No rewards available");
 
        uint256 rewardAmount = (feePool * userBalance) / totalStablecoin; // calculate reward proportionate to user's stablecoin balance
        require(rewardAmount > 0, "No rewards available");
        require(feePool >= rewardAmount, "Fee pool below reward amount");
 
        rewardBalanceOf[msg.sender] += rewardAmount;
        feePool -= rewardAmount;
        uint256 ethAmount = rewardAmount / (10 ** decimals); // convert stablecoin amount to Ether
        payable(msg.sender).transfer(ethAmount);
 
        emit RewardPaid(msg.sender, ethAmount);
    }
 


function checkFeePoolBalance() public view returns (uint256) {
    require(msg.sender == owner, "Only the contract owner can check the fee pool balance");
    return feePool;
}

function getRewardBalance(address _user) public view returns (uint256) {
    return rewardBalanceOf[_user];
}
function changeFeePercentage(uint256 _newFeePercentage) public {
    require(msg.sender == owner, "Only the contract owner can change the fee percentage");
    feePercentage = _newFeePercentage;
}

function changeFeePoolMinimum(uint256 _newFeePoolMinimum) public {
    require(msg.sender == owner, "Only the contract owner can change the fee pool minimum");
    feePoolMinimum = _newFeePoolMinimum;
 }

   

}