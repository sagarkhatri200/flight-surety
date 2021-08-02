import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, _owner, _web3) {
        let config = Config[network];
        this.flightSuretyApp = new _web3.eth.Contract(FlightSuretyApp.abi, config.appAddress, {gasLimit: "10000000"});
        this.owner = _owner;
        this.airlines = [];
        this.passengers = [];
        this.web3 = _web3;
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .call({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    addAirline(airlineAddress, airlineName, callback) {
        let self = this;
        let payload = {
            airlineName: airlineName
        } 
        self.flightSuretyApp.methods
            .registerAirline(airlineAddress, payload.airlineName)
            .send({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    fundAirline(airlineAddress, callback) {
        let self = this;
        let payload = {
            airlineAddress: airlineAddress
        } 
        self.flightSuretyApp.methods
            .fundAirline(airlineAddress)
            .send({ from: self.owner, value: "10000000000000000000"}, (error, result) => {
                callback(error, result);
            });
    }

    getApprovedAirlines(callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .getApprovedAirlines()
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    getAirline(address, callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .getAirline(address)
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    checkCredit(callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .checkCredits()
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    getFlightStatus(flightKey, callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .getFlightStatus(flightKey)
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    withdrawCredit(amount, callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .withDrawCredits(this.web3.utils.toWei(amount))
            .send({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }


    addFlight(airlineAddress, flight, callback) {
        let self = this;
        let payload = {
            airline: airlineAddress,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .registerFlight(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }
    
    getFlightsAvailableToBuyInsurance(callback) {
        let self = this;
        let payload = {
        } 
        self.flightSuretyApp.methods
            .getFlightsAvailableToBuyInsurance()
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }

    buyInsurance(flightKey, amount, callback) {
        let self = this;
        let payload = {
            flightKey: flightKey
        } 
        self.flightSuretyApp.methods
            .buyInsurance(flightKey)
            .send({ from: self.owner, value: this.web3.utils.toWei(amount)}, (error, result) => {
                callback(error, result);
            });
    }

    //submitToOracles
    submitToOracles(flightKey, callback) {
        let self = this;
        let payload = {
            flightKey: flightKey
        } 
        self.flightSuretyApp.methods
            .submitToOracles(flightKey)
            .send({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
    }
}