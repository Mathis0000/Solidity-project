// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error CollectIsFinished();
error GoalAlreadyReached();
error CollectNotFinished();
error FailedToSendEther();
error NoContribution();
error NotEnoughFunds();

contract Pool is ERC20,Ownable, ReentrancyGuard{
    uint256 public end;
    uint256 public goal;
    uint256 public totalCollected;
    uint256 public MaxSuply = 100000000* 10 ** uint(decimals());

    mapping (address => uint256) public contributions;

    event Contribute(address indexed contributor, uint256 amount);
        
    event Not_Contribute(address indexed contributor, uint256 amount);

    constructor(uint256 _duration, uint256 _goal,string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) ReentrancyGuard() {  //date de fin contrat+dure max
        end = block.timestamp + _duration;
        goal = _goal;
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }
    function getEnd() external view returns  (uint256){
        return end;
    }
        function getGoal() external view returns (uint256){
        return goal;
    }    
    function getBalance() external view returns (uint256){
        return totalCollected;
    }


    ///@notice contribute to the pool
    function contribute() external payable {
        //if (block.timestamp >= end) {       //meme que require
          //  revert CollectIsFinished();
        //}
        if(msg.value == 0){
            revert NotEnoughFunds();
        }

        contributions[msg.sender] += msg.value;
        totalCollected += msg.value;

        emit Contribute(msg.sender, msg.value); //pour le front
    }

    ///@notice allows the owner to withdraw
    function withdraw_token() external {
        // Ajoutez la validation de la fin de la collecte si nécessaire
        // if(block.timestamp < end || totalCollected < goal){
        //     revert CollectNotFinished();
        // }

        require(totalCollected > 0, "No contributions yet"); // Ajoutez une vérification pour éviter la division par zéro

        // Calcule la proportion des tokens à retirer en fonction de la contribution de l'utilisateur
        uint256 tokenAmountToWithdraw = (contributions[msg.sender] * MaxSuply) / totalCollected;

        // Vérifie si l'utilisateur a effectivement contribué
        require(tokenAmountToWithdraw > 0, "No contribution from the sender");
        contributions[msg.sender]= 0;
        // Transfère les tokens à l'utilisateur
        _mint(msg.sender, tokenAmountToWithdraw);

}


        ///@notice allows the owner to withdraw
    function withdraw() external onlyOwner{
        if(block.timestamp < end || totalCollected < goal){
            revert CollectNotFinished();
        }
        (bool sent,) = msg.sender.call{value: address (this).balance}("");  //retire les gains
        if(!sent){
            revert FailedToSendEther();
        }
    }

    function burn(address from, uint amount) external onlyOwner nonReentrant {
        _burn(from, amount);
    }
    ///@notice allows user to get money back
    function refund() external{
        //if(block.timestamp < end){
          //  revert CollectNotFinished();
        //}
        if (totalCollected >= goal){
            revert GoalAlreadyReached();
        }
        if(contributions[msg.sender] == 0){
            revert NoContribution();
        }
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender]= 0;
        totalCollected -= amount;

        (bool sent,) = msg.sender.call{value: amount}(""); //envoi
        if(!sent){
            revert FailedToSendEther();
        }

        emit Not_Contribute(msg.sender, amount); //pour le front

    }
}