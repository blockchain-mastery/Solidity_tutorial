pragma solidity ^0.8.16;

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        string name;
        uint voteCount;
    }

    address public chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    event Delegate(
        address sender,
        address receiver
    );

    event GiveRightToVote(
        address voter
    );

    event Vote(
        string name
    );

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can give right to vote.");
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0, "The voter has already gave right to vote.");
        voters[voter].weight = 1;
        
        emit GiveRightToVote(voter);
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have not gave right to vote yet!");
        require(!sender.voted, "You already voted.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1, "Cannot delegate to person, who have not been gave right to vote.");
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }

        emit Delegate({sender: msg.sender, receiver: to});
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender]; 
        require(sender.weight > 0, "You have no right to vote.");
        require(!sender.voted, "You already voted");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;

        emit Vote(proposals[proposal].name);
    }
    
    function winnerName() external view returns (string memory winnerProposalName) {
        uint indexWinningProposal = winningProposal();
        winnerProposalName = proposals[indexWinningProposal].name;
    }

    function winningProposal() public view returns (uint indexWinningProposal) {
        uint maxvoteCount = 0;
        for (uint i; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxvoteCount) {
                maxvoteCount = proposals[i].voteCount; 
                indexWinningProposal = i;
            }
        }
    }

    
}