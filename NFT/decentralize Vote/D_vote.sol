//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//importing required library(customized) and chainlink Automation contract
import "../Utilities/SimpleMath.sol";

//customize error Handling
error InvalidDuplicateVoterError(address spyVoter);
error VotingPeriodError(uint lasttimeofvote);
error InvalidVoteAmmount(uint numberAmountVoter, uint NumberCastingVote);
error _NoneVotedDuringVotingPeriod();

contract D_Vote {
    /**event handlers..... */
    event VoteEvent(bytes32 candidateId);
    event VoteStart(bytes32 _voteId);
    event Winners(bytes32[] _winners, uint NumberWinner);

    /**required library
     * @dev library for find out MaxNumber to counting vote
     * @dev function Name max() is used for geting greater number
     * @param uint[] dynamic array of uint input
     * @return uint Maxnumber ..... */
    using SimpleMath for uint;

    /**enum declaration  
     * @dev for declaring contract state situtaion 
       @dev 0 for enacting state
       @dev 1 for publicVoting state
      */
    enum Status {
        Enacting,
        publicVoting
    }

    Status public state;
    /**struct variable declaring............
     * @dev candidate for Candidates info.
     * @dev voters  for voters info.
     */
    struct candidate {
        bytes32 id;
        string name;
        uint castedVote;
    }
    struct voter {
        bool isVoter;
        bool hasVote;
        bytes32 validation;
    }

    /**mapping variable declarations...
     * @dev "hasVoted" for setting  voters info  using voters Address
     * @dev  "candidates" for setting candidate info using uinque candidate hash
     */
    mapping(address => voter) private hasVoted;
    mapping(bytes32 => candidate) private candidates;
    mapping(bytes32 => bytes32[]) private voteHistory;

    /**Array declarations...
     * @dev "voted" array of adding voter address after voted ;
     * @dev  "validCandidates" array of valid candidates
     */
    bytes32[] private validCandidates;
    address[] private validVoters;
    address[] private voted;

    /**voting period and timestamp declarations
     * @dev votingPeriod using for chainLink automation perform perpose
     * @dev lastTimeStamp for tracking checkUpkeep function to checking voting period
     *  to fired performupkepp function of chainlink automation .... */
    uint private votingPeriod;
    uint private lastTimeStamp;
    bytes32 private voteId;

    /**winners array to store previous winner and initialized before vote start */
    bytes32[] public winners;

    /**@dev adding candidate function
     * @dev private function to contracts use only
     * @dev to adding candidate to  genarate hash of candidate
     * @dev pushing candidate(hashId) to validCandidates Array
     * @dev mapping candidates by  key(bytes32 hasId) => value(struct candidateInfo)
     * @param _name of candidates ( using calldata location to avoid modification and reducing gas fee)
     */
    function addCandidate(string calldata _name) public returns (bool added) {
        require(
            state == Status.Enacting,
            "only can add when vote is in enacting state"
        ); //checking valid state to start the vote
        uint NumberOfCandidates = validCandidates.length;
        bytes32 hash_id = keccak256(
            abi.encodePacked(
                validCandidates.length,
                _name,
                msg.sender,
                block.timestamp
            )
        );
        candidates[hash_id] = candidate(hash_id, _name, 0);
        validCandidates.push(hash_id);
        return validCandidates.length == NumberOfCandidates++;
    }

    /**@dev adding Multiple candidate function
     * @dev public function to contracts use only
     * @dev to adding candidate to  genarate hash of candidate
     * @dev pushing candidate(hashId) to validCandidates Array
     * @dev mapping candidates by  key(bytes32 hasId) => value(struct candidateInfo)
     * @param _candidates Array of candidates ( using calldata location to avoid modification and reducing gas fee)
     */

    function addMultipleCandidate(
        string[] calldata _candidates
    ) public returns (bool) {
        require(
            state == Status.Enacting,
            "only can add when vote is in enacting state"
        ); //checking valid state to start the vote
        //looping through memory input _candidatees array to pushing the each of the candidate into validCandidates array
        for (uint i = 0; i < _candidates.length; i++) {
            addCandidate(_candidates[i]);
        }
        return true;
    }

    /**
     * @dev function addVoter to add voter to voters address
     * @param _voter voter address
     * @param _pinNumber pinNumber to cryptographically valided voter id
     * @return true if voter is successffully added to restricted voters array
     */
    function addVoter(address _voter, uint _pinNumber) public returns (bool) {
        require(
            state == Status.Enacting,
            "only can add when vote is in Enacting State"
        ); //checking valid state to start the vote
        require(_voter == address(0), "invalid voter address"); //checking valid address
        require(
            _voter.code.length > 0,
            "no contract are allowed to be a voter"
        ); //blocking contract address to be set as voter
        hasVoted[_voter].isVoter = true;
        hasVoted[_voter].hasVote = false;
        // generating voterId to set at validVoter
        hasVoted[_voter].validation = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, _voter, _pinNumber)
        );
        validVoters.push(_voter);
        return hasVoted[_voter].isVoter;
    }

    /**
     * @dev function add Multiple Voter to add voter to voters address
     * @param _voters Array voter addresses
     * @param _pinNumber pinNumber to cryptographically valided voter id
     * @return true if voters are successffully added to restricted voters array
     */
    function addMUltipleVoter(
        address[] calldata _voters,
        uint _pinNumber
    ) public returns (bool) {
        //looping through _voters array and mapping hasVoted set their validation
        for (uint i = 0; i < _voters.length; i++) {
            addVoter(_voters[i], _pinNumber);
        }
        return true;
    }

    /**@dev  function startVote to opening vote
     * @dev public function to interact voter to vote
     * @param _pinNumber to voterId to checking validVoters
     * @param _interval to set voting period(how long they can vote)
     *
     */
    function startVote(
        uint _pinNumber,
        uint _interval
    ) public returns (bool, bytes32) {
        //checking required state value
        require(state == Status.Enacting, "existing vote isnt ended yet"); //checking valid state to start the vote
        require(
            validCandidates.length > 1,
            "candidates not found to occuring vote"
        ); //checking valid candidate ammount
        require(voted.length == 0, "none can  vote before voting start");

        //intializing voting  settings by update state varaible
        votingPeriod = _interval;
        lastTimeStamp = block.timestamp;
        state = Status.publicVoting;
        voteId = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                block.timestamp,
                validVoters,
                validCandidates,
                _pinNumber
            )
        );
        emit VoteStart(voteId);
        //initializing previous winners array
        // winners = new bytes32[](0);
        return (state == Status.publicVoting, voteId);
    }

    /**modifier to checking validVoter
     * @dev checking valid -voter
    
     */
    modifier _onlyVoter() {
        require(hasVoted[msg.sender].isVoter == true, "nonValid Voter");
        require(hasVoted[msg.sender].hasVote == false, "already Voted");
        _;
    }

    /**function vote();
     * @dev to vote your chosen candidate
     * @param _candidateId of candidate valid hash-id
     * @param _pin valid pin id of voter
     * @dev _onlyVoter modifier chaecking valid Voter and duplicate voter
     */
    function Vote(bytes32 _candidateId, bytes32 _pin) public _onlyVoter {
        //checking required state varaible to let voter to vote
        require(hasVoted[msg.sender].validation == _pin, "invalid voter");
        //checking valid candidate id
        require(_validCandidate(_candidateId), "candidate isnt valid");
        require(
            state == Status.publicVoting,
            "voting isnt start or voting restriction isnt public"
        );
        if ((block.timestamp - lastTimeStamp) >= votingPeriod) {
            revert VotingPeriodError(lastTimeStamp + votingPeriod);
        }

        // record that voter has voted
        hasVoted[msg.sender].hasVote = true;
        hasVoted[msg.sender].validation = 0;
        voted.push(msg.sender);
        // update candidate vote Count
        candidates[_candidateId].castedVote++;
        emit VoteEvent(_candidateId);
    }

    function _validCandidate(
        bytes32 candidate_id
    ) private view returns (bool exist) {
        bytes32[] memory candidatesArray = validCandidates;
        for (uint i = 0; i < candidatesArray.length; i++) {
            if (candidatesArray[i] == candidate_id) {
                return true;
            }
        }
    }

    /** Counting vote function function
     * @dev counting votes after voting period has ended
     * @dev using customized MaxNumberLib to geting castedMaxVote
     * @dev set winner and multiple winners in winner Array
     * @dev initialized contracts state after succesfful decentralized autonomous voting period
     * @param _voteId to store winner by counting through votHistory mapping
     */
    function countingVote(bytes32 _voteId) internal {
        //checking voting period
        require(
            (block.timestamp - lastTimeStamp) >= votingPeriod,
            "vote hasnt ended yet"
        );
        //creating instance of candidates array in memory location to consume gas costing fee of loop caculation!
        bytes32[] memory candidatesArray = validCandidates;
        //creating voted voter array instance in memory location
        address[] memory votersArray = voted;
        //checking candidate perticipate? and anyone voted?
        require(candidatesArray.length > 1, "No candidate found");

        //if anyone voted then vote will be casted
        if (votersArray.length > 0) {
            // casting vote......
            uint totalvotes = 0;
            //creating a array to getting castedVote of candidate from struct mapping by id by for loop
            uint[] memory castingvote = new uint[](candidatesArray.length);
            for (uint i = 0; i < candidatesArray.length; i++) {
                //calculating  sum of totalcasting vote
                totalvotes += candidates[candidatesArray[i]].castedVote;
                //pushing the castedvote candidates mapping into temporary memory castingvote Array
                castingvote[i] = (candidates[candidatesArray[i]].castedVote);
            }
            //checking valid number of vote
            if (totalvotes != votersArray.length) {
                revert InvalidVoteAmmount(totalvotes, votersArray.length);
            }
            //calculationg greater number of vote by using customize max func of  maxNumber lib/
            uint maxNumber = SimpleMath.maxNumber(castingvote);
            // finding similar max voted winner or winner of max casting vote
            for (uint i = 0; i < castingvote.length; i++) {
                if (castingvote[i] == maxNumber) {
                    //pushing winning  candidate id to winners array
                    voteHistory[_voteId].push(validCandidates[i]);
                }
            }
            //emmiting Winners events
            emit Winners(voteHistory[_voteId], voteHistory[_voteId].length);
        } else {
            revert _NoneVotedDuringVotingPeriod();
        }

        //initializing voters array
        for (uint i = 0; i < votersArray.length; i++) {
            delete hasVoted[votersArray[i]];
        }
        //initializing state variable after calculating vote
        validCandidates = new bytes32[](0);
        voted = new address[](0);
        state = Status.Enacting;
        votingPeriod = 0;
        lastTimeStamp = 0;
        voteId = 0;
    }

    /**getter functions  */
    function getStatus() public view returns (string memory reply) {
        if (state == Status.Enacting) {
            return "Enacting State";
        }
        if (state == Status.publicVoting) {
            return "Running Public Vote State";
        }
    }

    function getVoterPin() public view _onlyVoter returns (bytes32) {
        return hasVoted[msg.sender].validation;
    }

    function voterState(address _voterAdd) public view returns (bool valid) {
        if (hasVoted[_voterAdd].isVoter == false) {
            revert InvalidDuplicateVoterError(_voterAdd);
        }
        return hasVoted[_voterAdd].hasVote; //return true if voter has voted
    }

    function hasVotingEnded() public view returns (bool valid) {
        return (block.timestamp - lastTimeStamp) > votingPeriod; //return true if vote ended
    }

    //getting function candidateInfo
    function CanidateInfo(
        string calldata _candidatesName
    )
        external
        view
        _onlyVoter
        returns (bytes32 candidateId, string memory name, uint castedNumberVote)
    {
        bytes32 paramStringhash = keccak256(abi.encodePacked(_candidatesName));
        bytes32[] memory canidatesArray = validCandidates;
        for (uint i = 0; i < canidatesArray.length; i++) {
            bytes32 candidatenameHash = keccak256(
                abi.encodePacked(candidates[canidatesArray[i]].name)
            );
            if (candidatenameHash == paramStringhash) {
                return (
                    candidates[canidatesArray[i]].id,
                    candidates[canidatesArray[i]].name,
                    candidates[canidatesArray[i]].castedVote
                );
            }
        }
    }

    function totalCandidates()
        public
        view
        returns (uint lengthNumberCandidate)
    {
        return validCandidates.length;
    }

    function totalVoters() public view returns (uint lenthOfVotersArray) {
        return voted.length;
    }

    function VoteWinner(
        bytes32 _voteId
    ) public view returns (uint winnerLength) {
        return voteHistory[_voteId].length;
    }
}
