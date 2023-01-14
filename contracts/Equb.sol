// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "./PriceConverter.sol";

contract Equb {
    using SafeMath for uint;
    using PriceConverter for uint256;

    uint256 public numberOfPools = 0;
    address timeContractAddress = 0x4385483b852D01655A7e760F616725C0c3db9873;
    BokkyPooBahsDateTimeContract timeContract =
        BokkyPooBahsDateTimeContract(timeContractAddress);
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
        string website;
        string twitterUrl;
        string facebookUrl;
        string telegramUrl;
        address[] members;
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

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
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
                _contributionAmount * 1e18,
                _contributionDate,
                0 * 1e18,
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
            // uint _contributionSkipCount,
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
                    PriceConverter.getConversionRate(
                        pools[i].contributionAmount,
                        priceFeed
                    ),
                    pools[i].contributionDate,
                    PriceConverter.getConversionRate(
                        pools[i].equbBalance,
                        priceFeed
                    ),
                    // pools[i].contributionSkipCount,
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

    function contribution(address equbAddress, address member) public payable {
        // Find the pool by equbAddress

        uint poolIndex = getPoolIndex(equbAddress);
        uint contAmount = msg.value.getConversionRate(priceFeed);
        require(
            contAmount == pools[poolIndex].contributionAmount,
            "Contribution amount is incorrect."
        );

        //check the member skip count
        uint skipCount = getRemainingSkipCount(equbAddress, member);
        if (skipCount < 3) {
            removeMember(equbAddress, member);
            revert(
                "You have skipped the contribution for three times, You will be removed from the pool."
            );
        }

        //Check the current date and compare it to the contribution date
        uint256 today = timeContract.getDay(block.timestamp);
        // uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
        // uint256 year = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
        //if the day pass
        if (today > pools[poolIndex].contributionDate) {
            //check if this is first time that member skip contribution
            if (contributions[equbAddress][member]) {
                //increment the skip count
                pools[poolIndex].contributionSkipCount += 1;
                //Emit event
                emit SkipContributionEvent(member, equbAddress);
                if (skipCount == 2) {
                    //remove the member from the pool
                    removeMember(equbAddress, member);
                    emit MemberRemovedEvent(member, equbAddress);
                }
            }
        } else {
            // Add the contribution amount to the pool balance
            pools[poolIndex].equbBalance += contAmount;

            // Mark the contribution as done
            contributions[equbAddress][member] = true;

            // Emit the Contribution event
            emit ContributionEvent(
                member,
                contAmount,
                pools[poolIndex].equbBalance
            );
            emit NextContributionTime(pools[poolIndex].contributionDate);
        }
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
