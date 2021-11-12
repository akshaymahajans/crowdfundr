pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
    uint256 private projectGoal;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public nftsDisbursed;
    address public creator;
    bool public goalSatisfied;
    bool public activeProject;
    

    modifier onlyActiveProject() {
        require(block.timestamp <= startTime + (30 days) + 900 seconds);
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
        require(totalContributed + msg.value >= msg.value);
        require(msg.value > .01 ether);
        require(goalSatisfied == false);
        totalContributed += msg.value;
        if (totalContributed >= projectGoal) {
            goalSatisfied = true;
        }
        contributions[msg.sender] += msg.value;
        uint nftsToDisburse = (contributions[msg.sender] / (1 ether)) - nftsDisbursed[msg.sender];
        
        if (nftsToDisburse > 0) {
            for (
                uint256 i = 0;
                i < nftsToDisburse;
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

    function closeProject()  public onlyOwner {
        activeProject = false;
    }

    function refund(address _caller) public onlyIfProjectFailed  (bool) {
        require(contributions[_caller] > 0);
        uint256 refundAmount = contributions[_caller];
        contributions[_caller] = 0;
        (bool refunded, ) = _caller.call{value: (refundAmount * 1 ether)}("");

        return refunded;
    }
    receive() external payable  {
        revert("");
    }

    fallback() external payable {
        revert();
    }
}
