// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proposal {
    struct ProposalData {
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

    mapping(address => ProposalData[]) public proposalsByPool;

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
            ProposalData(
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

    function getProposalsByPool(
        address _poolAddress
    ) public view returns (ProposalData[] memory) {
        return proposalsByPool[_poolAddress];
    }
}
