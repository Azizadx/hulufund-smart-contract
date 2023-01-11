// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Equb {
    using SafeMath for uint;
    uint256 public numberOfPools;
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
        uint contributionAmount;
        uint contributionDate;
        uint equbBalance;
        uint contributionSkipCount;
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

    // function getNumberOfPoolsByMember(
    //     address member
    // ) public view returns (uint) {
    //     uint count = 0;
    //     for (uint i = 0; i < pools.length; i++) {
    //         for (uint j = 0; j < pools[i].members.length; j++) {
    //             if (pools[i].members[j] == member) {
    //                 count++;
    //             }
    //         }
    //     }
    //     return count;
    // }

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
        return poolData;
    }

    function contribution(
        address equbAddress,
        address member,
        uint contAmount
    ) public {
        // Find the pool by equbAddress
        uint poolIndex;
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                poolIndex = i;
                break;
            }
        }
        require(
            contAmount == pools[poolIndex].contributionAmount,
            "Contribution amount is incorrect."
        );
        require(
            contributions[equbAddress][member] == false,
            "You have already contributed for this period."
        );
        require(
            pools[poolIndex].contributionSkipCount < 3,
            "You have skipped the contribution for three times, You will be removed from the pool."
        );
        //Check the current time and compare it to the contribution date
        uint currentTime = block.timestamp;
        uint contributionPeriod = currentTime -
            pools[poolIndex].contributionDate;
        require(
            contributionPeriod <= 60 * 60 * 24 * 30,
            "Contribution period has ended."
        );

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
    }

    function getPoolIndex(address equbAddress) private view returns (uint) {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == equbAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function skipContribution(address equbAddress, address member) public {
        uint index = getPoolIndex(equbAddress);
        require(
            !contributions[equbAddress][member],
            "You have already contributed for this period or already skipped it"
        );

        // Check if member has skipped the contribution for three times.
        if (pools[index].contributionSkipCount == 2) {
            removeFromArray(equbAddress, member);
            emit MemberRemovedEvent(member, equbAddress);
        } else {
            // Increment the skip count and mark the contribution as skipped
            pools[index].contributionSkipCount++;
            contributions[equbAddress][member] = true;

            // Emit the SkipContribution event
            emit SkipContributionEvent(member, equbAddress);
        }
    }

    function removeFromArray(address equbAddress, address member) private {
        uint index = getPoolIndex(equbAddress);
        // Iterate through the members array to find the index of the member
        for (uint i = 0; i < pools[index].members.length; i++) {
            if (pools[index].members[i] == member) {
                // Remove the member from the array
                delete pools[index].members[i];
                break;
            }
        }
    }
}
