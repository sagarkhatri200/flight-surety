pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/


    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers;

    struct FlightInsurance {
        address buyer;
        uint256 amount;
    }

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
        string flight;
        uint256 timestamp;
        bool isVerified;
        FlightInsurance[] flightInsurances;
    }
    mapping(string => Flight) private flights;

    address[] private approvedAirlinesArray = new address[](0);
    mapping(address => Airline) private allAirlines;
    
    struct Airline {
        uint8 status;
        string name;
        bool isFunded;
        RegistrationMetric registrationMetric;
    }

    struct RegistrationMetric {
        bool isRegistrationComplete;
        uint256 approvalsRequired;
        address[] approvers;
    }

    mapping(address => uint256) private insurerBalances;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
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

     modifier requireIsAuthorizedCaller()
    {
        require(authorizedCallers[msg.sender] == true, "Caller is not contract owner");
        _;
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

     /// @dev Add an authorized address
    function authorizeCaller(address _address) public requireContractOwner {
        authorizedCallers[_address] = true;
    }

    /// @dev Remove an authorized address
    function deAuthorizeCaller(address _address) private requireContractOwner {
        authorizedCallers[_address] = false;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(address airlineAddress,
                            string memory airlineName)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
        allAirlines[airlineAddress].status = 0;
        allAirlines[airlineAddress].name = airlineName;
        return true;
    }

    function updateAirline(address airlineAddress, uint8 status, bool isFunded)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
         allAirlines[airlineAddress].status = status;
         allAirlines[airlineAddress].isFunded = isFunded;
         if(status==1)
         {
            approvedAirlinesArray.push(airlineAddress);
         }
        return true;
    }

    function getApprovedAirlinesCount()
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (uint256 count)
    {
        return approvedAirlinesArray.length;
    }
    

    function getAirline(address airlineAddress)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (uint8, string memory, bool)
    {
        return (allAirlines[airlineAddress].status, allAirlines[airlineAddress].name, allAirlines[airlineAddress].isFunded);
    }

    function updateAirlineRegistration(address airlineAddress, bool isRegistrationComplete, uint256 approvalsRequired, address registrar)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
         allAirlines[airlineAddress].registrationMetric.isRegistrationComplete = isRegistrationComplete;
         allAirlines[airlineAddress].registrationMetric.approvalsRequired = approvalsRequired;
         if(registrar!=airlineAddress)
         {
            allAirlines[airlineAddress].registrationMetric.approvers.push(registrar);
         }
        return true;
    }

    function addAirlineRegistrationApproval(address airlineAddress, address approver)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
         allAirlines[airlineAddress].registrationMetric.approvers.push(approver);
        return true;
    }

     function getAirlineRegistrationDetail(address airlineAddress)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (bool, uint256, uint256)
    {
        return (allAirlines[airlineAddress].registrationMetric.isRegistrationComplete, allAirlines[airlineAddress].registrationMetric.approvalsRequired, allAirlines[airlineAddress].registrationMetric.approvers.length);
    }

    function isAirline(address _address)
                            public
                            view
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns(bool)
    {
        return allAirlines[_address].status == 1;
    }



    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        external
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function registerFlight(string memory flightKeyString, bool isRegistered, uint8 statusCode,uint256 updatedTimestamp, address airline, string memory flight, uint256 timestamp)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
        flights[flightKeyString].isRegistered = isRegistered;
        flights[flightKeyString].statusCode = statusCode;
        flights[flightKeyString].updatedTimestamp = updatedTimestamp;
        flights[flightKeyString].airline = airline;
        flights[flightKeyString].flight = flight;
        flights[flightKeyString].timestamp = timestamp;
        return true;
    }

    function getFlightStatus(string memory flightKeyString)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (uint8){
        return flights[flightKeyString].statusCode;        
    }

    function updateFlightDetail(string memory flightKeyString, uint8 statusCode, uint256 updatedTimestamp, bool isVerified)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
        flights[flightKeyString].statusCode = statusCode;
        flights[flightKeyString].updatedTimestamp = updatedTimestamp;
        flights[flightKeyString].isVerified = isVerified;
        return true;
    }

    function getFlightDetail(string memory flightKeyString)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (bool, address, string memory, uint256){
        return (flights[flightKeyString].isRegistered, flights[flightKeyString].airline, flights[flightKeyString].flight, flights[flightKeyString].timestamp);        
    }

    function addInsurancePurchase(string memory flightKey,address buyer, uint256 amount)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
        flights[flightKey].flightInsurances.push(FlightInsurance(buyer, amount));
        return true;
    }

    function getFlightInsurancesCount(string memory flightKeyString)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (uint256){
        return flights[flightKeyString].flightInsurances.length;        
    }

    function getFlightInsurancesDetail(string memory flightKeyString, uint256 index) public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            view
                            returns (address, uint256){
        return (flights[flightKeyString].flightInsurances[index].buyer, flights[flightKeyString].flightInsurances[index].amount);        
    }

    function updateInsureeCreditBalance(address insuree, uint256 newBalance)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (bool)
    {
        insurerBalances[insuree] =  newBalance;
        return true;
    }

    function getInsureeCreditBalance(address insuree)
                            public
                            requireIsAuthorizedCaller
                            requireIsOperational
                            returns (uint256)
    {
        return insurerBalances[insuree];
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() external{
    }
}

