// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract RaiseFundContract {
    // Struct to represent a fundraising campaign
    struct FundraisingCampaign {
        address owner; // The owner of the campaign
        string logoUrl; // URL for the campaign's logo
        string bannerUrl; // URL for the campaign's banner
        string name; // The name of the campaign
        string description; // A description of the campaign
        string videoUrl; // URL for a video about the campaign
        string industry; // The industry the campaign belongs to
        uint256 amountRaised; // The total amount raised by the campaign
        uint256 goal; // The fundraising goal for the campaign
        uint256 minInvestment; // The minimum investment allowed for the campaign
        uint256 valuationCap; // The valuation cap for the campaign
        uint256 discountRate; // The discount rate for the campaign
        uint256 deadline; // The deadline for the campaign to reach its goal
        address[] investors; // A list of addresses of investors in the campaign
    }
    //event
    event CampaignCreated(
        uint256 numberOfCampaigns,
        string name,
        uint256 goal,
        uint256 deadline
    );
    // event
    event FundWithdrawn(uint256 index, string name, uint amount);
    event InvestmentMade(uint256 id, address investor, uint amount);

    // Mapping from campaign ID to campaign data
    mapping(uint256 => FundraisingCampaign) public campaigns;
    mapping(address => uint256) public ownerCampaignCount;
    mapping(address => uint256) public ownerCampaign;
    mapping(address => bool) public investorsInCampaign;

    // The total number of campaigns
    uint256 public numberOfCampaigns = 0;

    // Function to create a new fundraising campaignmapping(address => uint256) public ownerCampaignCount;
    function createCampaign(
        string memory _logoUrl,
        string memory _bannerUrl,
        string memory _name,
        string memory _description,
        string memory _industry,
        string memory _videoUrl,
        uint256 _goal,
        uint256 _minInvestment,
        uint256 _valuationCap,
        uint256 _discountRate,
        uint256 _deadline
    ) public returns (uint256) {
        // Check that the owner has not exceeded the maximum number of campaigns
        require(
            ownerCampaignCount[msg.sender] < 1,
            "The owner has exceeded the maximum number of campaigns"
        );

        // Check that the deadline is in the future
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future"
        );

        // Check that the minimum investment is a positive number
        require(
            _minInvestment > 0,
            "The minimum investment must be a positive number"
        );

        // Check that the goal is a positive number
        require(_goal > 0, "The goal must be a positive number");

        // Increment the number of campaigns created by the owner
        ownerCampaignCount[msg.sender]++;

        // Initialize the new campaign
        FundraisingCampaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = msg.sender;
        campaign.logoUrl = _logoUrl;
        campaign.bannerUrl = _bannerUrl;
        campaign.name = _name;
        campaign.description = _description;
        campaign.industry = _industry;
        campaign.videoUrl = _videoUrl;
        campaign.goal = _goal;
        campaign.amountRaised = 0;
        campaign.minInvestment = _minInvestment;
        campaign.valuationCap = _valuationCap;
        campaign.discountRate = _discountRate;
        campaign.deadline = _deadline;
        numberOfCampaigns++;

        // Log the creation of a new campaign
        emit CampaignCreated(numberOfCampaigns - 1, _name, _goal, _deadline);

        return numberOfCampaigns - 1; // Return the ID of the newly created campaign
    }

    // Function to get a list of all campaigns
    function getCampaigns() public view returns (FundraisingCampaign[] memory) {
        FundraisingCampaign[] memory allCampaigns = new FundraisingCampaign[](
            numberOfCampaigns
        );

        for (uint i = 0; i < numberOfCampaigns; i++) {
            FundraisingCampaign storage campaign = campaigns[i];
            allCampaigns[i] = campaign;
        }

        return allCampaigns;
    }

    // Function to unlock the funds when the deadline and goal are reached
    function unlockFunds(address _owner) public view returns (bool) {
        uint256 campaignsIndex;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == _owner) {
                campaignsIndex = i;
                break;
            }
        }

        if (
            (block.timestamp > campaigns[campaignsIndex].deadline &&
                campaigns[campaignsIndex].amountRaised >=
                campaigns[campaignsIndex].goal) ||
            (block.timestamp < campaigns[campaignsIndex].deadline &&
                campaigns[campaignsIndex].amountRaised >=
                campaigns[campaignsIndex].goal)
        ) {
            // campaigns[campaignsIndex].status.fundsLocked = false;
            return true;
        } else {
            return false; //funds locked
        }
    }

    //function for owner to withdraw funds
    function withdraw(address payable _owner) public {
        // Check that the msg.sender is the owner of the campaign
        require(
            msg.sender == _owner,
            "Only the campaign owner can withdraw the funds."
        );

        // Find the campaign index for the owner
        uint256 campaignIndex;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == _owner) {
                campaignIndex = i;
                break;
            }
        }

        // Check that the campaign index is valid
        require(campaignIndex < numberOfCampaigns, "Invalid campaign ID");

        // Check that the contract has enough balance to transfer to the owner
        require(
            address(this).balance >= campaigns[campaignIndex].amountRaised,
            "Contract has insufficient balance"
        );

        // Transfer the raised funds to the campaign owner
        _owner.transfer(campaigns[campaignIndex].amountRaised);

        // Emit the FundWithdrawn event
        emit FundWithdrawn(
            campaignIndex,
            campaigns[campaignIndex].name,
            campaigns[campaignIndex].amountRaised
        );

        // Reset the amount raised for the campaign
        campaigns[campaignIndex].amountRaised = 0;
    }

    // Function to get a campaign by its owner's address
    function getCampaignByOwnerAddress(
        address _ownerAddress
    ) public view returns (FundraisingCampaign[] memory) {
        FundraisingCampaign[]
            memory matchingCampaigns = new FundraisingCampaign[](
                numberOfCampaigns
            );
        uint256 numMatchingCampaigns = 0;

        for (uint i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == _ownerAddress) {
                FundraisingCampaign storage campaign = campaigns[i];
                matchingCampaigns[numMatchingCampaigns] = campaign;
                numMatchingCampaigns++;
            }
        }

        if (numMatchingCampaigns == 0) {
            revert("No campaigns found for the given owner address");
        }

        return matchingCampaigns;
    }

    function getStartupIndex(address startup) public view returns (uint) {
        for (uint i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == startup) {
                return i;
            }
        }
        revert("startup not found");
    }

    function getFundRaiseGoal(address startup) public view returns (uint) {
        //get the startup index
        uint startupIndex = getStartupIndex(startup);
        return campaigns[startupIndex].goal;
    }

    function getMimiInvestment(address startup) public view returns (uint) {
        //get the startup index
        uint startupIndex = getStartupIndex(startup);
        return campaigns[startupIndex].minInvestment;
    }

    function investInCampaign(
        address payable _startup,
        address payable equbAddress
    ) external payable {
        require(
            equbAddress != _startup,
            "you cant invest to  your own startup"
        );
        uint256 campaignId;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == _startup) {
                campaignId = i;
                break;
            }
        }
        // Check that the campaign exists
        require(
            campaignId < numberOfCampaigns,
            "The specified campaign does not exist"
        );

        // Check that the investment amount is at least the minimum investment
        require(
            msg.value >= campaigns[campaignId].minInvestment,
            "The investment must be at least the minimum investment"
        );
        // require(
        //     goal <= campaigns[campaignId].goal,
        //     "The investment can not be larger than fund raise goal"
        // );
        // Check that the campaign deadline has not passed
        require(
            block.timestamp <= campaigns[campaignId].deadline,
            "The campaign deadline has passed"
        );

        // Check that the investor has not already invested in the campaign
        require(
            !investorsInCampaign[msg.sender],
            "You have already invested in this campaign"
        );
        campaigns[campaignId].amountRaised += msg.value;
        // Add the investor's address to the list of investors
        campaigns[campaignId].investors.push(equbAddress);
        // Add the investor's address to the list of investors
        investorsInCampaign[msg.sender] = true;
    }

    // Function to get a list of investors in a campaign

    function getInvestors(
        uint256 _campaignId
    ) public view returns (address[] memory) {
        // Get the campaign data
        FundraisingCampaign storage campaign = campaigns[_campaignId];

        // Check that the campaign exists
        require(
            _campaignId < numberOfCampaigns,
            "The specified campaign does not exist"
        );

        return campaign.investors;
    }
}
