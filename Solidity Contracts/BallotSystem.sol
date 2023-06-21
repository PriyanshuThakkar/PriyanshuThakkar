// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BallotSystem {
    //enum Party{BJP,CONGRESS}
    struct candidate {
        string name;
        uint8 partyNumber;
        uint256 voteCount;
        bool ValidCandidate;
    }
    struct Voter {
        bool ValidVoter;
        bool Voted;
    }
    uint256 public Party1Candidates;
    uint256 public Party2Candidates;
    uint256 Party1VoteCount;
    uint256 Party2VoteCount;
    //uint256 public TimeStartForVoting;
    uint256 public TimeStopForVoting;
    //candidate[] nominees;
    address[] Candidate_Adress; //To store  addresses of all the registered candidates
    mapping(address => candidate) public Candidate_fetch;
    //mapping(address => bool) public Voted;
    //mapping(address => bool) public Voter_Validity;
    mapping(address => Voter) public Voter_fetch;
    //mapping(address => bool) public Candidate_Validity;
    mapping(uint8 => string) internal PartyName;
    address public owner;
    uint256 public VoterCount;
    uint256 public NumberOfVotes;
    bool public RegistrationStatus; // To know if the owner has started the registration
    bool public VotingStatus; // To know if the owner has started the voting
    bool public StopVotingStatus; //To capture if voting time is over

    constructor() {
        owner = msg.sender;
        PartyName[1] = "BJP";
        PartyName[2] = "CONGRESS";
    }

    function isOwner() internal view returns (bool) {
        if (msg.sender == owner) {
            return true;
        } else {
            return false;
        }
    }

    function Start_Registration() external returns (bool) {
        require(isOwner(), "Only the Owner can initiate the Registration.");
        RegistrationStatus = true;
        return RegistrationStatus;
    }

    function Start_Voting() external returns (bool) {
        require(isOwner(), "Only the Owner can initiate the process.");
        require(
            Party1Candidates >= 5 && Party2Candidates >= 5,
            "Minimum Five Candidates per Party to Start Voting."
        );
        //TimeStartForVoting = block.timestamp;
        TimeStopForVoting = block.timestamp + 200;
        RegistrationStatus = false;
        VotingStatus = true;
        return VotingStatus;
    }

    function showPartyNames()
        external
        pure
        returns (string memory, string memory)
    {
        return ("Party-1 is BJP", "Party-2 is CONGRESS");
    }

    function currentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setCandidate(
        //TODO: check for candidate address as msg.snder
        //TODO: check address(0) optional
        string memory _name,
        address _candidateId,
        uint8 _partyNumber
    ) external {
        require(
            RegistrationStatus,
            "Candidate Registration has not started yet."
        );
        require(msg.sender != owner, "Owner Cannot be a Candidate.");
        require(
            msg.sender == _candidateId,
            "You can only register for yourself"
        );
        require(
            Candidate_fetch[_candidateId].ValidCandidate == false,
            "Candidate cannot register themselves again."
        );
        //require(
        //_partyNumber == 1 || _partyNumber == 2,
        //"Valid Party Numbers are 1 and 2."
        //);
        if (_partyNumber == 1 && Party1Candidates < 10) {
            Party1Candidates += 1;
        } else if (_partyNumber == 2 && Party2Candidates < 10) {
            Party2Candidates += 1;
        } else {
            revert(
                "Invalid Party Number added or the Party you want to Join is Full."
            );
        }
        Candidate_fetch[_candidateId].ValidCandidate = true;
        Candidate_fetch[_candidateId].partyNumber = _partyNumber;
        Candidate_fetch[_candidateId].name = _name;
        Candidate_Adress.push(_candidateId);
        setVoterId(_candidateId);
    }

    function setVoterId() external {
        require(
            Voter_fetch[msg.sender].ValidVoter == false,
            "Voters cannot register themselves again."
        );
        Voter_fetch[msg.sender].ValidVoter = true;
        VoterCount++;
        //Voter_Validity[_voterId] = true;
    }

    function setVoterId(address _voterId) internal {
        require(
            Voter_fetch[_voterId].ValidVoter == false,
            "Voters cannot register themselves again."
        );
        Voter_fetch[_voterId].ValidVoter = true;
        VoterCount++;
        //Voter_Validity[_voterId] = true;
    }

    function Voting(address _toCandidate) public {
        require(VotingStatus, "Voting has not started yet.");
        require(block.timestamp < TimeStopForVoting, "Voting is finished.");
        // if(block.timestamp>=TimeStopForVoting - 60)
        // {
        //     TimeStopForVoting = block.timestamp + 180;
        // }
        if (block.timestamp < TimeStopForVoting - 60) {
            require(
                Voter_fetch[msg.sender].ValidVoter,
                "You are not a registered Voter."
            );
            require(
                Voter_fetch[msg.sender].Voted == false,
                "You have already Voted."
            );
            require(
                Candidate_fetch[_toCandidate].ValidCandidate,
                "Selected Candidate is not a Valid Candidate."
            );
            Voter_fetch[msg.sender].Voted = true;
            Candidate_fetch[_toCandidate].voteCount += 1;
            NumberOfVotes++;
            if (Candidate_fetch[_toCandidate].partyNumber == 1) {
                Party1VoteCount += 1;
            } else {
                Party2VoteCount += 1;
            }
        }
        if (
            block.timestamp >= TimeStopForVoting - 60 &&
            block.timestamp < TimeStopForVoting
        ) {
            TimeStopForVoting = block.timestamp + 180;
        } else {
            VotingStatus = false;
            StopVotingStatus = true;
            revert("Voting finished.");
        }
    }

    // function StopVoting() public returns (bool) {
    //     require(isOwner(), "Only the Owner can initiate the process.");
    //     VotingStatus = false;
    //     StopVotingStatus = true;
    //     return StopVotingStatus;
    // }

    function Winner() external view returns (candidate memory, string memory) {
        require(StopVotingStatus, "Voting has not Finished Yet.");
        uint256 winner = 0;
        for (uint256 i = 1; i < Candidate_Adress.length; i++) {
            if (
                Candidate_fetch[Candidate_Adress[winner]].voteCount <
                Candidate_fetch[Candidate_Adress[i]].voteCount
            ) {
                winner = i;
            }
        }
        return (
            (Candidate_fetch[Candidate_Adress[winner]]),
            (
                string.concat(
                    "Party Winner: ",
                    PartyName[
                        Candidate_fetch[Candidate_Adress[winner]].partyNumber
                    ]
                )
            )
        );
    }
}
