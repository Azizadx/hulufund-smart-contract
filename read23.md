// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzepplin/contracts/Payable.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "./PriceConsumerV3.sol";
import "./lib/PriceConverter.sol";

contract Equb {
    using SafeMath for uint;
    using PriceConverter for uint256;

    uint256 public numberOfPools = 0;
    address timeContractAddress = 0x4385483b852D01655A7e760F616725C0c3db9873;
    address priceConvertAddress = 0xC33a770be3E9358bdf3876d6aD0eba8fF6B4F70a;

    BokkyPooBahsDateTimeContract timeContract =
        BokkyPooBahsDateTimeContract(timeContractAddress);

    PriceConsumerV3 priceConsumer = PriceConsumerV3(priceConvertAddress);
    AggregatorV3Interface public priceFeed;
    struct PoolData {
        address equbAddress;
        string poolName;
        string poolImage;
    }
    struct Proposal {
        address poolAddress;
        address proposer;
        string title;
        string description;
        address startupAddress;
        string startupWebsite;
        string proposerTwitter;
        string proposerTelegram;
        string proposerFacebook;
    }
    struct Pool {
        address equbAddress;
        string name;
        string profileUrl;
        string email;
        string description;
        uint contributionAmount; //will be save in wei
        uint contributionDate; //5
        uint equbBalance;
        uint contributionSkipCount; //no need in frontend;
        string website;
        string twitterUrl;
        string facebookUrl;
        string telegramUrl;
        address[] members;
    }

    Pool[] public pools;
    // Proposal[] proposals;
    mapping(address => mapping(address => bool)) public contributions;
    mapping(address => Proposal[]) public proposalsByPool;

    event ContributionEvent(
        address member,
        uint256 contributeAmount,
        uint256 daoBalance
    );

    event SkipContributionEvent(address member, address equbAddress);
    event MemberRemovedEvent(address member, address equbAddress);
    event NextContributionTime(uint time);
    event Success(string message);
    event Action(
        address indexed initiator,
        string message,
        address indexed beneficiary,
        uint256 amount
    );

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function hasContributed(
        address equbAddress,
        address member
    ) public view returns (bool) {
        return contributions[equbAddress][member];
    }

    function createProposal(
        address _poolAddress,
        address _proposer,
        string memory _title,
        string memory _description,
        address _startupAddress,
        string memory _startupWebsite,
        string memory _proposerTwitter,
        string memory _proposerTelegram,
        string memory _proposerFacebook
    ) public {
        proposalsByPool[_poolAddress].push(
            Proposal(
                _poolAddress,
                _proposer,
                _title,
                _description,
                _startupAddress,
                _startupWebsite,
                _proposerTwitter,
                _proposerTelegram,
                _proposerFacebook
            )
        );
    }

    function createEqub(
        string memory _name,
        string memory _profileUrl,
        string memory _email,
        string memory _description,
        uint _contributionAmount,
        uint _contributionDate,
        // uint _timeStamp,
        string memory _website,
        string memory _twitterUrl,
        string memory _facebookUrl,
        string memory _telegramUrl,
        address[] memory _members
    ) public {
        require(_members.length <= 10, "Maximum of 10 members can contribute");
        // Check if the sender (creator) has already created a pool
        for (uint i = 0; i < pools.length; i++) {
            require(
                pools[i].equbAddress != msg.sender,
                "Only one pool creation per address is allowed"
            );
        }
        pools.push(
            Pool(
                msg.sender,
                _name,
                _profileUrl,
                _email,
                _description,
                _contributionAmount,
                _contributionDate,
                0,
                0,
                _website,
                _twitterUrl,
                _facebookUrl,
                _telegramUrl,
                _members
            )
        );
        numberOfPools += 1;
        // Initialize contribution records for members
        for (uint i = 0; i < _members.length; i++) {
            contributions[msg.sender][_members[i]] = false;
        }
        // uint timestamp = getCountDown()
    }

    function getProposalsByPool(
        address _poolAddress
    ) public view returns (Proposal[] memory) {
        return proposalsByPool[_poolAddress];
    }

    function getPool(
        address equbAddress
    )
        public
        view
        returns (
            address _equbAddress,
            string memory _name,
            string memory _profileUrl,
            string memory _email,
            string memory _description,
            uint _contributionAmount,
            uint _contributionDate,
            uint _equbBalance,
            string memory _website,
            string memory _twitterUrl,
            string memory _facebookUrl,
            string memory _telegramUrl,
            address[] memory _members
        )
    {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                return (
                    pools[i].equbAddress,
                    pools[i].name,
                    pools[i].profileUrl,
                    pools[i].email,
                    pools[i].description,
                    pools[i].contributionAmount,
                    pools[i].contributionDate,
                    pools[i].equbBalance,
                    pools[i].website,
                    pools[i].twitterUrl,
                    pools[i].facebookUrl,
                    pools[i].telegramUrl,
                    pools[i].members
                );
            }
        }
        revert("No pool created by this address");
    }

    function getPoolByMember(
        address member
    ) public view returns (PoolData[] memory) {
        PoolData[] memory poolData = new PoolData[](numberOfPools);
        uint k = 0;
        for (uint i = 0; i < pools.length; i++) {
            for (uint j = 0; j < pools[i].members.length; j++) {
                if (pools[i].members[j] == member) {
                    poolData[k] = PoolData(
                        pools[i].equbAddress,
                        pools[i].name,
                        pools[i].profileUrl
                    );
                    k++;
                }
            }
        }
        require(k > 0, "Member not found in any pool.");
        return poolData;
    }

    function getPoolIndex(address equbAddress) private view returns (uint) {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function getRemainingSkipCount(
        address equbAddress,
        address member
    ) public view returns (uint) {
        // Find the pool by equbAddress
        uint poolIndex;
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                poolIndex = i;
                break;
            }
        }
        // Check if the member has contributed
        if (!contributions[equbAddress][member]) {
            // If the member has not contributed, skipsLeft = 3
            return 3;
        } else {
            // If the member has contributed, calculate skipsLeft
            return 3 - pools[poolIndex].contributionSkipCount;
        }
    }

    function setFlag(uint contDay) public view returns (bool) {
        bool flag;
        if (contDay <= timeContract.getDay(block.timestamp)) {
            return flag = false;
        } else {
            return flag = true;
        }
    }

    function getCountDown(uint contDay) public view returns (uint) {
        //get the day from
        bool flag = setFlag(contDay);
        uint countDow;
        // uint theDay = timeContract.getDay(block.timestamp); //18
        uint theMonth = timeContract.getMonth(block.timestamp);
        uint theYear = timeContract.getYear(block.timestamp);
        if (flag == false) {
            if (theMonth == 12) {
                uint theUpcoming = timeContract.timestampFromDate(
                    theYear + 1,
                    theMonth + 1,
                    contDay
                );
                countDow = theUpcoming;
                return countDow;
            } else {
                uint theUpcoming = timeContract.timestampFromDate(
                    theYear,
                    theMonth + 1,
                    contDay
                );
                countDow = theUpcoming;
                return countDow;
            }
        }
        //if the contribution start it
        else {
            uint theUpcoming = timeContract.timestampFromDate(
                theYear,
                theMonth,
                contDay
            );
            countDow = theUpcoming;
            return countDow;
        }
    }

    function removeMember(address equbAddress, address member) internal {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                address[] memory members = pools[i].members;
                for (uint j = 0; j < members.length; j++) {
                    if (members[j] == member) {
                        //delete the member from the array
                        delete members[j];
                        //update the member array
                        pools[i].members = members;
                        break;
                    }
                }
            }
        }
    }
}
// function contribution(
    //     address equbAddress,
    //     address member
    // ) external payable {
    //     // Find the pool by equbAddress

    //     uint poolIndex = getPoolIndex(equbAddress);
    //     uint amount = (
    //         priceConsumer.convertUsdToEth(pools[poolIndex].contributionAmount)
    //     ) * 100000000;
    //     // uint amountWei = amount * 100000000;
    //     //check the member skip count
    //     uint skipCount = getRemainingSkipCount(equbAddress, member);
    //     if (skipCount < 3) {
    //         removeMember(equbAddress, member);
    //         revert(
    //             "You have skipped the contribution for three times, You will be removed from the pool."
    //         );
    //     }
    //     uint contAmount = msg.value * 1e18;

    //     pools[poolIndex].equbBalance = (contAmount +
    //         pools[poolIndex].equbBalance);
    //     // require(
    //     //      msg.value == amount,
    //     //     "The cont amount must be equal to contributionAmount"
    //     // );

    //     // (bool success, ) = payable(member).call{value: address(this).balance}(
    //     //     ""
    //     // );

    //     // // // If the transfer was successful, update the amount raised by the
    //     // if (success) {

    //     // } else {
    //     //     revert("tansraction didnt go through");
    //     // }

    //     // Mark the contribution as done
    //     contributions[equbAddress][member] = true;
    //     emit Action(
    //         msg.sender,
    //         "CONTRIBUTION RECEIVED",
    //         address(equbAddress),
    //         msg.value
    //     );

    //     // Emit the Contribution event
    //     emit ContributionEvent(member, amount, pools[poolIndex].equbBalance);
    //     uint256 nextContribution = getCountDown(
    //         pools[poolIndex].contributionDate
    //     );
    //     emit NextContributionTime(nextContribution);
    //     //covert the contribution funcation

    //     //Check the current date and compare it to the contribution date
    //     // uint256 today = getCountDown(pools[poolIndex].contributionDate,);
    //     //check if this is first time that member skip contribution
    //     // if (contributions[equbAddress][member]) {
    //     //     //increment the skip count
    //     //     pools[poolIndex].contributionSkipCount += 1;
    //     //     //Emit event
    //     //     emit SkipContributionEvent(member, equbAddress);
    //     //     if (skipCount == 2) {
    //     //         //remove the member from the pool
    //     //         removeMember(equbAddress, member);
    //     //         emit MemberRemovedEvent(member, equbAddress);
    //     //     }
    //     // } else {
    //     // Add the contribution amount to the pool balance
    // }


    function getTimestampFromTxHash(bytes32 txHash) public view returns (uint) {
        bytes32 blockHash = txHash;
        if (block.isEIP158(blockHash)) {
            blockHash = block.blockhash(block.number);
        }
        Block memory block = block.info(blockHash);
        return block.timestamp;
    }

    // function getTimestamp(bytes32 zzz) public view returns (uint256, bool){

    //     //Fetching the block that is associated with transaction hash zzz
    //     Block memory bbb = block.byhash(zzz);

    //     //If block is not found, then return nothing, else return its timestamp and true boolean value
    //    if(iszero(bbb.blockHash)){
    //      return (0,false);
    //     }else{
    //      return (bbb.timestamp, true);
    //     }
    // }

    function getMonthBasedStartupAddress(
        address equbAddress,
        address startup
    ) public view returns (uint) {
        //get the index of equb address
        uint poolIndex = getPoolIndex(equbAddress);
        uint month;
        //access the proposal based on the equb index
        //access proposal
        for (uint i = 0; i < proposalsCount[equbAddress]; i++) {
            if (proposalsByPool[equbAddress][i].startupAddress == startup) {
                //the startup is found
                uint txHash = Proposal[i].txHash;
                //call the timestamp of that block
                uint timeStamp = getTransactionTimestamp(txHash);
                //get the month from the returning timestamp
                month = timeContract.getMonth(timeStamp);
            }
        }
        return month;
    }

    function getMonthlyContributors(
        address equbAddress,
        uint month
    ) public view returns (address[] memory) {
        address[] memory contributors = new address[](
            countContributor[equbAddress][month]
        );
        for (uint i = 0; i < countContributor[equbAddress][month]; i++) {
            address member = contribut[equbAddress];
            if (countContributor[equbAddress][month] > 0) {
                contributors[i] += member;
            }
        }
        return contributors;
    }



    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzepplin/contracts/Payable.sol";
// import "@openzeppelin/contracts/block/Block.sol";

import "./BokkyPooBahsDateTimeContract.sol";
import "./PriceConsumerV3.sol";
import "./lib/PriceConverter.sol";
import "./RaiseFundContract.sol";

contract Equb {
    using SafeMath for uint;
    using PriceConverter for uint256;

    uint256 public numberOfPools = 0;
    address timeContractAddress = 0x4385483b852D01655A7e760F616725C0c3db9873;
    address priceConvertAddress = 0xC33a770be3E9358bdf3876d6aD0eba8fF6B4F70a;
    BokkyPooBahsDateTimeContract timeContract =
        BokkyPooBahsDateTimeContract(timeContractAddress);

    PriceConsumerV3 priceConsumer = PriceConsumerV3(priceConvertAddress);
    AggregatorV3Interface public priceFeed;

    RaiseFundContract fundStartup =
        RaiseFundContract(0xdbAEE04cb4bfdC9DBeD4d4e35E2e52061bE1b9cA);

    event InvestmentMade(uint256 id, address investor, uint amount);

    struct PoolData {
        address equbAddress;
        string poolName;
        string poolImage;
    }
    struct Proposal {
        address poolAddress;
        address proposer;
        string title;
        string description;
        address startupAddress;
        string startupWebsite;
        string proposerTwitter;
        string proposerTelegram;
        string proposerFacebook;
        uint voteDuration;
        // bytes32 transactionHash;
        bool status;
        uint yay;
        uint nay;
    }
    struct Pool {
        address equbAddress;
        string name;
        string profileUrl;
        string email;
        string description;
        uint contributionAmount; //will be save in wei
        uint contributionDate; //5
        uint equbBalance;
        uint contributionSkipCount; //no need in frontend;
        string website;
        string twitterUrl;
        string facebookUrl;
        string telegramUrl;
        address[] members;
    }

    Pool[] public pools;
    // Proposal[] proposals;
    mapping(address => mapping(address => mapping(uint => bool)))
        public contributions;
    mapping(address => mapping(uint => uint)) public countContributor;
    mapping(address => address) public contribut;
    mapping(address => Proposal[]) public proposalsByPool;
    mapping(address => uint) public proposalsCount;
    mapping(address => mapping(address => mapping(uint => bool))) public Voters;

    event ContributionEvent(
        address member,
        uint256 contributeAmount,
        uint256 daoBalance
    );

    event SkipContributionEvent(address member, address equbAddress);
    event MemberRemovedEvent(address member, address equbAddress);
    event NextContributionTime(uint time);
    event Success(string message);
    event Action(
        address indexed initiator,
        string message,
        address indexed beneficiary,
        uint256 amount
    );

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /***
     * The write functions that display data about the smart contract
     */

    function createProposal(
        address _poolAddress,
        address _proposer,
        string memory _title,
        string memory _description,
        address _startupAddress,
        string memory _startupWebsite,
        string memory _proposerTwitter,
        string memory _proposerTelegram,
        string memory _proposerFacebook
    ) public {
        uint votingDuration = block.timestamp + 7 days; //timestamp in weeks
        // bytes32 txHash = keccak256(
        //     abi.encodePacked(block.timestamp, block.number, address(this))
        // );
        proposalsByPool[_poolAddress].push(
            Proposal(
                _poolAddress,
                _proposer,
                _title,
                _description,
                _startupAddress,
                _startupWebsite,
                _proposerTwitter,
                _proposerTelegram,
                _proposerFacebook,
                votingDuration,
                true,
                0,
                0
            )
        );
        proposalsCount[_poolAddress]++;
    }

    function createEqub(
        string memory _name,
        string memory _profileUrl,
        string memory _email,
        string memory _description,
        uint _contributionAmount,
        uint _contributionDate,
        string memory _website,
        string memory _twitterUrl,
        string memory _facebookUrl,
        string memory _telegramUrl,
        address[] memory _members
    ) public {
        require(_members.length <= 10, "Maximum of 10 members can contribute");
        // Check if the sender (creator) has already created a pool
        for (uint i = 0; i < pools.length; i++) {
            require(
                pools[i].equbAddress != msg.sender,
                "Only one pool creation per address is allowed"
            );
        }
        pools.push(
            Pool(
                msg.sender,
                _name,
                _profileUrl,
                _email,
                _description,
                _contributionAmount,
                _contributionDate,
                0,
                0,
                _website,
                _twitterUrl,
                _facebookUrl,
                _telegramUrl,
                _members
            )
        );
        numberOfPools += 1;
        // Initialize contribution records for members
        for (uint i = 0; i < _members.length; i++) {
            contributions[msg.sender][_members[i]][
                timeContract.getMonth(block.timestamp)
            ] = false;
        }
        // uint timestamp = getCountDown()
    }

    function contribute(
        address payable equbAddress,
        address member // uint256 usdAmount
    ) public payable {
        uint poolIndex = getPoolIndex(equbAddress);

        uint skipCount = getRemainingSkipCount(equbAddress, member);
        if (skipCount == 0) {
            removeMember(equbAddress, member);
            revert(
                "You have skipped the contribution for three times, You will be removed from the pool."
            );
        }
        // if the timestamp pass the time count escpe and generate the next timestamp
        else {
            require(
                msg.sender.balance >= msg.value,
                "Insufficient funds in wallet"
            );
            // require(msg.sender != equbAddress, "Cannot transfer to self");

            (bool success, ) = equbAddress.call{value: msg.value}("");
            if (success) {
                pools[poolIndex].equbBalance += msg.value;
                emit Action(msg.sender, "transferred", equbAddress, msg.value);
            } else {
                revert("Fund didnt send");
            }

            contributions[equbAddress][member][
                timeContract.getMonth(block.timestamp)
            ] = true;
            countContributor[equbAddress][
                timeContract.getMonth(block.timestamp)
            ]++;
            contribut[equbAddress] = member;
            emit Action(
                msg.sender,
                "CONTRIBUTION RECEIVED",
                address(equbAddress),
                msg.value
            );

            // Emit the Contribution event
            emit ContributionEvent(
                member,
                msg.value,
                pools[poolIndex].equbBalance
            );
            uint256 nextContribution = getCountDown(
                pools[poolIndex].contributionDate
            );
            emit NextContributionTime(nextContribution);
        }
    }

    function voteOnProposal(
        address equbAddress,
        address member,
        uint proposalId,
        bool vote
    ) public returns (uint[] memory) {
        require(
            !Voters[equbAddress][member][proposalId],
            "You have already voted on this proposal."
        );
        Proposal storage proposal = proposalsByPool[equbAddress][proposalId];
        require(proposal.status, "This proposal is no longer active.");
        if (vote) {
            proposal.yay++;
        } else {
            proposal.nay++;
        }
        Voters[equbAddress][member][proposalId] = true;
        //number of voters in that month
        uint[] memory result = new uint[](2);
        result[0] = proposal.yay;
        result[1] = proposal.nay;
        return result;
    }

    function mostVotedProposal(
        address equbAddress
    ) public view returns (address) {
        uint maxVotes = 0;
        uint mostVotedProposalIndex;
        for (uint i = 0; i < proposalsCount[equbAddress]; i++) {
            if (proposalsByPool[equbAddress][i].yay > maxVotes) {
                maxVotes = proposalsByPool[equbAddress][i].yay;
                mostVotedProposalIndex = i;
            }
        }
        return
            proposalsByPool[equbAddress][mostVotedProposalIndex].startupAddress;
    }

    function hasContributed(
        address equbAddress,
        address member
    ) public view returns (bool) {
        return
            contributions[equbAddress][member][
                timeContract.getMonth(block.timestamp)
            ];
    }

    function hasVoted(
        address equbAddress,
        address member,
        uint proposalId
    ) public view returns (bool) {
        return Voters[equbAddress][member][proposalId];
    }

    /***
     * The read functions that display data about the smart contract
     */
    function getProposalsByPool(
        address _poolAddress
    ) public view returns (Proposal[] memory) {
        return proposalsByPool[_poolAddress];
    }

    function getPool(
        address equbAddress
    )
        public
        view
        returns (
            address _equbAddress,
            string memory _name,
            string memory _profileUrl,
            string memory _email,
            string memory _description,
            uint _contributionAmount,
            uint _contributionDate,
            uint _equbBalance,
            string memory _website,
            string memory _twitterUrl,
            string memory _facebookUrl,
            string memory _telegramUrl,
            address[] memory _members
        )
    {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                return (
                    pools[i].equbAddress,
                    pools[i].name,
                    pools[i].profileUrl,
                    pools[i].email,
                    pools[i].description,
                    pools[i].contributionAmount,
                    pools[i].contributionDate,
                    pools[i].equbBalance,
                    pools[i].website,
                    pools[i].twitterUrl,
                    pools[i].facebookUrl,
                    pools[i].telegramUrl,
                    pools[i].members
                );
            }
        }
        revert("No pool created by this address");
    }

    function getPoolByMember(
        address member
    ) public view returns (PoolData[] memory) {
        PoolData[] memory poolData = new PoolData[](numberOfPools);
        uint k = 0;
        for (uint i = 0; i < pools.length; i++) {
            for (uint j = 0; j < pools[i].members.length; j++) {
                if (pools[i].members[j] == member) {
                    poolData[k] = PoolData(
                        pools[i].equbAddress,
                        pools[i].name,
                        pools[i].profileUrl
                    );
                    k++;
                }
            }
        }
        require(k > 0, "Member not found in any pool.");
        return poolData;
    }

    function getPoolIndex(address equbAddress) private view returns (uint) {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function getEqubName(
        address equbAddress
    ) public view returns (string memory) {
        //find the equb index
        uint poolIndex = getPoolIndex(equbAddress);
        require(poolIndex > 0, "Equb is not found");
        //return the name
        return pools[poolIndex].name;
    }

    function getRemainingSkipCount(
        address equbAddress,
        address member
    ) public view returns (uint) {
        // Find the pool by equbAddress
        uint poolIndex;
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                poolIndex = i;
                break;
            }
        }
        // Check if the member has contributed
        if (
            !contributions[equbAddress][member][
                timeContract.getMonth(block.timestamp)
            ]
        ) {
            // If the member has not contributed, skipsLeft = 3
            return 3;
        } else {
            // If the member has contributed, calculate skipsLeft
            return 3 - pools[poolIndex].contributionSkipCount;
        }
    }





}


// // Function for investors to invest in a campaign
    // function investInCampaign(address startup) public payable {
    //     // uint256 campaignId = ownerCampaign[startup];
    //     uint256 campaignIndex;
    //     for (uint256 i = 0; i < numberOfCampaigns; i++) {
    //         if (campaigns[i].owner == startup) {
    //             campaignIndex = i;
    //             break;
    //         }
    //     }
    //     require(campaignIndex < numberOfCampaigns, "Invalid campaign ID");
    //     // require(msg.sender == startup, "You cant invest to your own campaign");
    //     require(
    //         msg.value >= campaigns[campaignIndex].minInvestment,
    //         "Investment amount is less than the minimum investment allowed"
    //     );
    //     campaigns[campaignIndex].amountRaised += msg.value;
    //     campaigns[campaignIndex].investors.push(msg.sender);
    //     emit InvestmentMade(campaignIndex, msg.sender, msg.value);
    // }


    // Send the investment amount to the campaign owner
    // (bool success, ) = payable(campaigns[campaignId].owner).call{
    //     value: msg.value
    // }("");

    // // If the transfer was successful, update the amount raised by the campaign
    // if (success) {}

     // require(
    //     campaigns[campaignIndex].amountRaised == 0,
    //     "No funds to withdraw"
    // );
    // (bool callSuccess, ) = _owner.call{
    //     value:
    // }("");
    // require(callSuccess, "Call failed");
    // _owner.transfer();
    // function withdraw(address payable _owner) public payable {
    //     // bool locked = unlockFunds(_owner);
    //     // Find the campaign index for the owner
    //     uint256 campaignIndex;
    //     for (uint256 i = 0; i < numberOfCampaigns; i++) {
    //         if (campaigns[i].owner == _owner) {
    //             campaignIndex = i;
    //             break;
    //         }
    //     }
    //     require(msg.sender == _owner, "Only owner can withdraw the funds.");
    //     // require(
    //     //     locked,
    //     //     "Funds are locked. Wait till deadline is reached or goal is met."
    //     // );
    //     _owner.transfer(campaigns[campaignIndex].amountRaised);
    //     emit FundWithdrawn(
    //         campaignIndex,
    //         campaigns[campaignIndex].name,
    //         campaigns[campaignIndex].amountRaised
    //     );
    // }