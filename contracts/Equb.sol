// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzepplin/contracts/Payable.sol";
// import "@openzeppelin/contracts/block/Block.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
    RaiseFundContract contractInstance;

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

    constructor(address priceFeedAddress, address raiseFund) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        contractInstance = RaiseFundContract(raiseFund);
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
        require(poolIndex < pools.length, "Equb is not found");
        //return the name
        string memory equbName = pools[poolIndex].name;
        return equbName;
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
        uint theDay = timeContract.getDay(block.timestamp); //18
        uint theMonth = timeContract.getMonth(block.timestamp);
        uint theYear = timeContract.getYear(block.timestamp);
        if (flag == false && theDay > contDay) {
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
            if (contDay > theDay) {
                uint theUpcoming = timeContract.timestampFromDate(
                    theYear,
                    theMonth,
                    contDay
                );
                countDow = theUpcoming;
                return countDow;
            } else if (contDay <= theDay) {
                uint theUpcoming = timeContract.timestampFromDate(
                    theYear,
                    theMonth + 1, //start from the next month
                    contDay
                );
                countDow = theUpcoming;
                return countDow;
            }
        }
        return countDow;
    }

    function releaseFund(address equbAddress) public view returns (bool) {
        uint day = timeContract.getDay(block.timestamp);
        uint poolIndex = getPoolIndex(equbAddress);
        if (pools[poolIndex].contributionDate == day) {
            return true;
        } else {
            return false;
        }
    }

    function investInStartup(
        address payable _startup,
        address payable equbAddress
    ) public payable {
        uint poolIndex = getPoolIndex(equbAddress);
        uint amount = pools[poolIndex].equbBalance;
        contractInstance.investInCampaign{value: amount}(_startup, equbAddress);
        pools[poolIndex].equbBalance = 0;
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
