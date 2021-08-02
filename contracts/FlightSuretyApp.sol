pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;
// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyData.sol";


/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    FlightSuretyData private flightSuretyData;


    address private contractOwner;          // Account used to deploy contract
    bool private operational = true;

    uint8 private constant MIN_AIRLINES_WITHOUT_CONSENSUS = 4;
    uint256 public constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256 public constant MAX_INSURED_AMOUNT = 1 ether;
    string[] private formattedApprovedAirlinesArray = new string[](0);
    string[] private formattedApprovedFlightsArray = new string[](0);


    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    enum AirlineState{
        New, //0
        Active //1
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
   modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract)
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

       /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    function strConcat(string memory _a,
                        string memory _b,
                        string memory _c,
                        string memory _d,
                        string memory _e)
                        internal
                        returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
    }

    function addressToString(address _addr)
                        public
                        pure
                        returns(string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function bytes32ToString(bytes32 value)
                            public
                            pure
                            returns(string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function initialize()
                            public
                            requireIsOperational
                            requireContractOwner
    {
        address airlineAddress = 0xf17f52151EbEF6C7334FAD080c5704D77216b732;
        string memory airlineName = "Spirit Airlines";
        string memory flight = "SA-DFW-LAS-14032";

        _registerAirline(airlineAddress, airlineName);
        //_registerFlight(airlineAddress, flight, block.timestamp);
    }
  
   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline(address airlineAddress,
                            string memory airlineName)
                            public
                            requireIsOperational
    {
        uint256 currentApprovedAirlinesCount = flightSuretyData.getApprovedAirlinesCount();
        require(
            (airlineAddress == msg.sender && currentApprovedAirlinesCount >= MIN_AIRLINES_WITHOUT_CONSENSUS) ||
            (currentApprovedAirlinesCount < MIN_AIRLINES_WITHOUT_CONSENSUS && flightSuretyData.isAirline(msg.sender) == true),
        "Existing Airlines registers upto 4. airlines themselves register after.");

        return _registerAirline(airlineAddress, airlineName);
    }

    function _registerAirline(address airlineAddress,
                            string memory airlineName)
                            private
    {
        flightSuretyData.registerAirline(airlineAddress, airlineName);
        uint256 approvedAirlinesCount = flightSuretyData.getApprovedAirlinesCount();
        
        if(approvedAirlinesCount < MIN_AIRLINES_WITHOUT_CONSENSUS)
        {
            flightSuretyData.updateAirlineRegistration(airlineAddress, true, 0, msg.sender);
        } else{
            flightSuretyData.updateAirlineRegistration(airlineAddress, false, approvedAirlinesCount.div(2).add(1), msg.sender);
        }
    }

    function fundAirline(address airlineAddress)
                            public
                            requireIsOperational
                            payable
    {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Airline registration fee is 10 ether and is required.");
        (uint8 status, , bool isFunded) = flightSuretyData.getAirline(airlineAddress);
        flightSuretyData.updateAirline(airlineAddress,status,true);
        checkApproval(airlineAddress);
    }

    function checkApproval(address airlineAddress)
                            internal
    {
         (uint8 status, , bool isFunded) = flightSuretyData.getAirline(airlineAddress);
         if(status == uint8(AirlineState.New) && isFunded)
         {
             (bool isRegistrationComplete,,) = flightSuretyData.getAirlineRegistrationDetail(airlineAddress);

            if(isRegistrationComplete)
            {
                flightSuretyData.updateAirline(airlineAddress,1,isFunded);
                 (, string memory airlineName,) = flightSuretyData.getAirline(airlineAddress);
                string memory addressString = addressToString(airlineAddress);
                string memory airlinesString = strConcat(addressString, "|",airlineName,"", "");
                formattedApprovedAirlinesArray.push(airlinesString);
            }
        }
    }

    function getApprovedAirlinesCount()
                            public
                            requireIsOperational
                            view
                            returns (uint256 count)
    {
        return flightSuretyData.getApprovedAirlinesCount();
    }

    function isAirline(address _address)
                            public
                            requireIsOperational
                            view
                            returns(bool)
    {
        return flightSuretyData.isAirline(_address);
    }

    function approveAirline(address airlineAddress)
                            public
                            requireIsOperational
    {
        require(flightSuretyData.isAirline(msg.sender) == true, "only Existing Airlines can approve new Airlines.");

        flightSuretyData.addAirlineRegistrationApproval(airlineAddress, msg.sender);

        (bool isRegistrationComplete,
         uint256 approvalsRequired,
          uint256 approversLength) = flightSuretyData.getAirlineRegistrationDetail(airlineAddress);
        if(approversLength >= approvalsRequired && isRegistrationComplete == false){

            flightSuretyData.updateAirlineRegistration(airlineAddress, true, approvalsRequired, msg.sender);
            
            checkApproval(airlineAddress);
        }
    }

    function getAirline(address airlineAddress)
                            public
                            requireIsOperational
                            view
                            returns (string memory)
    {
        (, string memory airlineName,) = flightSuretyData.getAirline(airlineAddress);
        return airlineName;
    }

    function getApprovedAirlines
                            (
                            )
                            public
                            requireIsOperational
                            view
                            returns (string[] memory)
    {
        return formattedApprovedAirlinesArray;
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(address airlineAddress,
                            string memory flight,
                            uint256 timestamp
                                )
                                public
                                requireIsOperational
                                returns (string memory)
    {
        require(flightSuretyData.isAirline(airlineAddress),"Airline is not registered or has not been approved to add flights.");
        require(bytes(flight).length<=20,"Flight Name should not be greater than 20 characters.");

        return _registerFlight(airlineAddress, flight, timestamp);
    }

    function _registerFlight(address airlineAddress,
                            string memory flight,
                            uint256 timestamp
                                )
                                private
                                requireIsOperational
                                returns (string memory)
    {
        bytes32 flightKey = flightSuretyData.getFlightKey(airlineAddress, flight, timestamp);
        string memory flightKeyString = bytes32ToString(flightKey);

        flightSuretyData.registerFlight(flightKeyString, true, 0, block.timestamp, airlineAddress, flight, timestamp);
        
        (, string memory airlineName,) = flightSuretyData.getAirline(airlineAddress);
        string memory flightString = strConcat(airlineName, "|",flight,"|", flightKeyString);
        formattedApprovedFlightsArray.push(flightString);
        return flightString;
    }

    function getFlightStatus(string memory flightKeyString)
                            public
                            requireIsOperational
                            view
                            returns (string memory)
    {
        uint8 statusCode = flightSuretyData.getFlightStatus(flightKeyString);
        if(statusCode==10){
            return "ON-TIME";
        }else if(statusCode==20){
            return "LATE-AIRLINE";
        }else if(statusCode==30){
            return "LATE-WEATHER";
        }else if(statusCode==40){
            return "LATE-TECHNICAL";
        }else if(statusCode==50){
            return "LATE-OTHER";
        }else {
            return "UNKNOWN";
        }
    }

    function getFlightsAvailableToBuyInsurance
                            (
                            )
                            public
                            requireIsOperational
                            view
                            returns (string[] memory)
    {
        return formattedApprovedFlightsArray;
    }

    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 finalStatus
                                )
                                internal
    {
       

        bytes32 flightKey = flightSuretyData.getFlightKey(airline, flight, timestamp);
        string memory flightKeyString = bytes32ToString(flightKey);

        flightSuretyData.updateFlightDetail(flightKeyString, finalStatus, block.timestamp, true);
        
        if(finalStatus == STATUS_CODE_LATE_AIRLINE)
        {
            uint256 flightInsuranceCount = flightSuretyData.getFlightInsurancesCount(flightKeyString);
            for(uint i = 0; i < flightInsuranceCount; i++)
            {
                (address buyer, uint256 amountInsured) = flightSuretyData.getFlightInsurancesDetail(flightKeyString, i);
                uint256 amountWinning = amountInsured.mul(3).div(2);
                uint256 insureeBalance = flightSuretyData.getInsureeCreditBalance(buyer);
                uint256 newBalance = insureeBalance.add(amountWinning);
                flightSuretyData.updateInsureeCreditBalance(buyer, newBalance);
            }
        }

    }

    function submitToOracles(
                            string memory flightKey
                            )
                        public
                        requireIsOperational
    {

        (bool isRegistered, address airline, string memory flight, uint256 timestamp) = flightSuretyData.getFlightDetail(flightKey);
        require(isRegistered==true, "flight key is not registered.");

        fetchFlightStatus(airline, flight, timestamp);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        public
                        requireIsOperational
    {
        bytes32 flightKey = flightSuretyData.getFlightKey(airline, flight, timestamp);
        string memory flightKeyString = bytes32ToString(flightKey);
        (bool isRegistered, , , ) = flightSuretyData.getFlightDetail(flightKeyString);
        require(isRegistered==true, "flight key is not registered.");

        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key].requester = msg.sender;
        oracleResponses[key].isOpen = true;

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function buyInsurance(string memory flightKey
                            )
                            external
                            payable
                            requireIsOperational
    {
        require(msg.value <= MAX_INSURED_AMOUNT,"Invalid insurance amount. max is 1 ether.");
          (bool isRegistered, address airline, string memory flight, uint256 timestamp) = flightSuretyData.getFlightDetail(flightKey);
        require(isRegistered==true, "flight key is not registered.");

        flightSuretyData.addInsurancePurchase(flightKey, msg.sender, msg.value);
    }


    function checkCredits()
                            public
                            returns (uint256)
    {
        return flightSuretyData.getInsureeCreditBalance(msg.sender);
    }

    function withDrawCredits(uint256 amount)
                            public
                            requireIsOperational
    {
        uint256 insureebalance = flightSuretyData.getInsureeCreditBalance(msg.sender);
        require(amount <= insureebalance, "Insufficient fund!!");

        uint256 newBalance = insureebalance.sub(amount);
        flightSuretyData.updateInsureeCreditBalance(msg.sender, newBalance);
        payable(msg.sender).transfer(amount);
    }


    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle(
                            )
                            external
                            payable
                            requireIsOperational
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes(
                            )
                            view
                            public
                            requireIsOperational
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        public
                        requireIsOperational
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        //require(oracleResponses[key].isOpen == true, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES && oracleResponses[key].isOpen == true) {
            oracleResponses[key].isOpen = false;

            uint unknownCounts = oracleResponses[key].responses[0].length;
            uint onTimeCounts = oracleResponses[key].responses[10].length;
            uint lateAirlineCounts = oracleResponses[key].responses[20].length;
            uint weatherCounts = oracleResponses[key].responses[30].length;
            uint technicalsCounts = oracleResponses[key].responses[40].length;
            uint otherCounts = oracleResponses[key].responses[50].length;

            uint8 finalStatus = STATUS_CODE_UNKNOWN;
            uint largestCounts = unknownCounts;
            if(largestCounts <= onTimeCounts){
                finalStatus = STATUS_CODE_ON_TIME;
                largestCounts = onTimeCounts;
            }
            if(largestCounts <= lateAirlineCounts){
                finalStatus = STATUS_CODE_LATE_AIRLINE;
                largestCounts = lateAirlineCounts;
            }
            if(largestCounts <= weatherCounts){
                finalStatus = STATUS_CODE_LATE_WEATHER;
                largestCounts = weatherCounts;
            }
            if(largestCounts <= technicalsCounts){
                finalStatus = STATUS_CODE_LATE_WEATHER;
                largestCounts = technicalsCounts;
            }
            if(largestCounts <= otherCounts){
                finalStatus = STATUS_CODE_LATE_OTHER;
                largestCounts = otherCounts;
            }

            emit FlightStatusInfo(airline, flight, timestamp, finalStatus);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, finalStatus);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(
                                address account
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}
