// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract QuadraticFunding {
    address public admin;
    uint256 public matchingPool;
    uint256 public projectCount;

    struct Project {
        string name;
        string description;
        string imageURI;
        address payable recipient;
        uint256 totalRaised;
        uint256 uniqueDonors;
        uint256 sqrtSum;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public donations;
    
    event ProjectRegistered(uint256 indexed projectId, string name, address recipient);
    event Donation(address indexed donor, uint256 indexed projectId, uint256 amount);
    event MatchingDistributed(uint256 totalPool, uint256 projectsCount);

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        matchingPool += msg.value;
    }

    function fundMatchingPool() external payable {
        matchingPool += msg.value;
    }

    function registerProject(string calldata name, string calldata description, string calldata imageURI) external {
        projectCount++;
        projects[projectCount] = Project(name, description, imageURI, payable(msg.sender), 0, 0, 0);
        emit ProjectRegistered(projectCount, name, msg.sender);
    }

    function donate(uint256 projectId) external payable {
        require(msg.value > 0, "Donation must be > 0");
        require(projectId > 0 && projectId <= projectCount, "Invalid project");

        Project storage p = projects[projectId];
        uint256 previousDonation = donations[projectId][msg.sender];
        
        if (previousDonation == 0) {
            p.uniqueDonors++;
        } else {
            p.sqrtSum -= sqrt(previousDonation);
        }

        donations[projectId][msg.sender] += msg.value;
        p.sqrtSum += sqrt(donations[projectId][msg.sender]);
        p.totalRaised += msg.value;

        emit Donation(msg.sender, projectId, msg.value);
    }

    function distributeMatching() external {
        require(msg.sender == admin, "Only admin");
        require(matchingPool > 0, "Empty pool");

        uint256 totalSqrtSum = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            totalSqrtSum += (projects[i].sqrtSum * projects[i].sqrtSum);
        }

        uint256 poolToDistribute = matchingPool;
        matchingPool = 0;

        for (uint256 i = 1; i <= projectCount; i++) {
            Project storage p = projects[i];
            if (p.sqrtSum > 0 && totalSqrtSum > 0) {
                uint256 matchAmount = (poolToDistribute * (p.sqrtSum * p.sqrtSum)) / totalSqrtSum;
                if (matchAmount > 0) {
                    (bool ok, ) = p.recipient.call{value: matchAmount}("");
                    require(ok, "Transfer failed");
                }
            }
            // Reset for next round
            p.totalRaised = 0;
            p.uniqueDonors = 0;
            p.sqrtSum = 0;
        }
        
        emit MatchingDistributed(poolToDistribute, projectCount);
    }

    // Babylonian method for square root
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
