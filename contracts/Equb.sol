// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Equb {
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
        uint contributionDate; //30
        string website;
        string twitterUrl;
        string facebookUrl;
        string telegramUrl;
        address[] members;
    }

    Pool[] public pools;

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
                _website,
                _twitterUrl,
                _facebookUrl,
                _telegramUrl,
                _members
            )
        );
        numberOfPools += 1;
    }

    function getPool(
        address creator
    )
        public
        view
        returns (
            address _creator,
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
        )
    {
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i].equbAddress == creator) {
                return (
                    pools[i].equbAddress,
                    pools[i].name,
                    pools[i].profileUrl,
                    pools[i].email,
                    pools[i].description,
                    pools[i].contributionAmount,
                    pools[i].contributionDate,
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

    function getNumberOfPoolsByMember(
        address member
    ) public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < pools.length; i++) {
            for (uint j = 0; j < pools[i].members.length; j++) {
                if (pools[i].members[j] == member) {
                    count++;
                }
            }
        }
        return count;
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
        return poolData;
    }
}
