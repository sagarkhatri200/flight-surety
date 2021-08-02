const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = async (deployer) => {

    await deployer.deploy(FlightSuretyData,  {gas: 4500000});
    await deployer.deploy(FlightSuretyApp, FlightSuretyData.address,  {gas: 8000000000});
    let config = {
        localhost: {
            url: 'http://localhost:8545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
        }
    }
    
    // Initial Setup
    let flightSuretyDataInstance = await FlightSuretyData.deployed();
    await flightSuretyDataInstance.authorizeCaller(FlightSuretyApp.address);
    
    let flightSuretyAppInstance = await FlightSuretyApp.deployed();
    await flightSuretyAppInstance.initialize();
    
    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
};