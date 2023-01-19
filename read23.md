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
        // uint timeStampe;
        string website;
        string twitterUrl;
        string facebookUrl;
        string telegramUrl;
        address[] members;
    }
    struct CountDown {
        uint timestamp;
    }

    struct Proposal {
        address equbAddress;
        address proposer;
        string title;
        string decsription;
        address startupAddress;
        string startupWebsite;
        string proposerTwitter;
        string proposerTelegram;
        string proposerFacebook;
    }

    Pool[] public pools;
    mapping(address => mapping(address => bool)) public contributions;

    event ContributionEvent(
        address member,
        uint256 contributeAmount,
        uint256 daoBalance
    );

    event SkipContributionEvent(address member, address equbAddress);
    event MemberRemovedEvent(address member, address equbAddress);
    event NextContributionTime(uint time);
    event Success(string message);

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function hasContributed(
        address equbAddress,
        address member
    ) public view returns (bool) {
        return contributions[equbAddress][member];
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
