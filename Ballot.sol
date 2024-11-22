// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


contract Ballot {

    struct Voter {
        uint weight;  // Accumulated voting weight from delegations
        bool voted;   // Whether the voter has already voted
        address delegate; // Address of the voter they delegated to
        uint vote;    // Index of the voted proposal (if any)
    }

    struct Proposal {
        bytes32 name;       // Short name (up to 32 bytes)
        uint voteCount;    // Number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

 
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }


    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only chairperson can grant voting rights.");
        require(!voters[voter].voted, "Voter already voted.");
        require(voters[voter].weight == 0, "Voter already has voting rights.");
        voters[voter].weight = 1;
    }

  
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is not allowed.");

        // Check for delegation loops
        address current = to;
        while (voters[current].delegate != address(0)) {
            current = voters[current].delegate;
            require(current != msg.sender, "Found loop in delegation.");
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // Directly add weight to delegate's proposal
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // Add weight to delegate's total voting power
            delegate_.weight += sender.weight;
        }
    }


    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

}