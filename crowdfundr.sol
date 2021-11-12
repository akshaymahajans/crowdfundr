pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ProjectFactory {
    mapping(address => Project[]) public projects;

    function createProject(
        uint256 _projectGoal,
        address _owner
    ) public {
        Project project = new Project(_projectGoal, _owner);
        projects[_owner].push(project);
    }
}
  
contract Project is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public startTime;
    uint256 public totalContributed;
    uint256 public projectGoal;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public nftsDisbursed;
    address public creator;
    bool public goalSatisfied;
    bool public activeProject;
    

    modifier onlyActiveProject() {
        require(block.timestamp <= startTime + (30 days));
        require(activeProject);
        _;
    }
    modifier onlyIfGoalReached() {
        require(goalSatisfied == true);
        _;
    }

    modifier onlyIfProjectFailed() {
        require(goalSatisfied == false);
        require(activeProject == false);
        _;
    }

    constructor(
        uint256 _projectGoal,
        address _owner
    ) ERC721("contributoooor", "CT") {
        transferOwnership(_owner);
        projectGoal = _projectGoal * 1 ether;
        goalSatisfied = false;
        activeProject = true;
        startTime = block.timestamp;
        creator = _owner;
    }

    function mintNFT(address recipient) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        return newItemId;
    }
    function contribute() public payable onlyActiveProject {
        require(msg.value > .01 ether);
        require(goalSatisfied == false);
        totalContributed += msg.value;
        if (totalContributed >= projectGoal) {
            goalSatisfied = true;
        }
        contributions[msg.sender] += msg.value;

        if (
            ((contributions[msg.sender] / (1 ether)) -
                nftsDisbursed[msg.sender]) > 0
        ) {
            for (
                uint256 i = 0;
                i <
                (contributions[msg.sender] / (1 ether)) -
                    nftsDisbursed[msg.sender];
                i++
            ) {
                mintNFT(msg.sender);
                nftsDisbursed[msg.sender] += 1;
            }
        }
    }

    function withdraw(uint256 _requestedwithdrawalAmount)
        public
        onlyOwner
        onlyIfGoalReached
        returns (bool)
    {
        require(_requestedwithdrawalAmount <= totalContributed);
        (bool sent, ) = creator.call{
            value: (_requestedwithdrawalAmount * 1 ether)
        }("");
        if (sent == true){
            totalContributed -= (_requestedwithdrawalAmount * 1 ether);
        }
        return sent;
    }

    function closeProject() public onlyOwner onlyIfGoalReached {
        //add in logic to set inactivie and set to close
        activeProject = false;
    }

    function refund(address _caller) public onlyIfProjectFailed returns (bool) {
        require(contributions[_caller] > 0);
        uint256 refundAmount = contributions[_caller];
        contributions[_caller] = 0;
        (bool refunded, ) = _caller.call{value: (refundAmount * 1 ether)}("");

        return refunded;
    }
}
