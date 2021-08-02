
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyApp.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  // Multiparty Consensus - Only existing airline may register a new airline until there are at least four airlines registered
  it('existing airline may register a new airline until there are at least four airlines registered', async () => {
    
    // ARRANGE
    let firstAirline = accounts[1];
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    
    await config.flightSuretyApp.fundAirline(firstAirline, {from: firstAirline, value:'10000000000000000000'});
    // ACT   
    await config.flightSuretyApp.registerAirline(newAirline2, 'Delta Airlines', {from: config.firstAirline});
    await config.flightSuretyApp.registerAirline(newAirline3, 'United Airlines', {from: config.firstAirline});
    await config.flightSuretyApp.registerAirline(newAirline4, 'American Airlines', {from: config.firstAirline});
    await config.flightSuretyApp.fundAirline(newAirline2, {from: newAirline2, value:'10000000000000000000'});
    await config.flightSuretyApp.fundAirline(newAirline3, {from: newAirline3, value:'10000000000000000000'});
    await config.flightSuretyApp.fundAirline(newAirline4, {from: newAirline4, value:'10000000000000000000'});
    
    let result2 = await config.flightSuretyApp.isAirline(newAirline2); 
    assert.equal(result2, true, "existing airline may register a new airline until there are at least four airlines registered");
    let result3 = await config.flightSuretyApp.isAirline(newAirline3); 
    assert.equal(result3, true, "existing airline may register a new airline until there are at least four airlines registered");
    let result4 = await config.flightSuretyApp.isAirline(newAirline4); 
    assert.equal(result4, true, "existing airline may register a new airline until there are at least four airlines registered");

    // For Fifth one. Existing Airline cannot add more. Airlines themselves have to add themselves
    let errorOccured = false;
    try{
      await config.flightSuretyApp.registerAirline(newAirline5, 'Eithad Airlines', {from: config.firstAirline});
    }catch(e){
      errorOccured = true;
    }

    assert.equal(errorOccured, true, "existing airline cannot register beyond 4");
    let result5 = await config.flightSuretyApp.isAirline(newAirline5); 
    assert.equal(result5, false, "fifth airline should not have been added.");
    
  });

  // Multiparty Consensus - Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
  it('Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
    
    // ARRANGE
    let firstAirline = accounts[1];
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    
    // ACT   
    // For Fifth one. New Airlines have to add themselves. Once Existing Airlines approve by 50% consesus, it would be approved.
    await config.flightSuretyApp.registerAirline(newAirline5, 'Eithad Airlines', {from: newAirline5});
    await config.flightSuretyApp.fundAirline(newAirline5, {from: newAirline5, value:'10000000000000000000'});
    
    let result5 = await config.flightSuretyApp.isAirline(newAirline5); 
    assert.equal(result5, false, "fifth airline should not have been added.");
    
    //3 votes needed
  //Send consesus via approval
  await config.flightSuretyApp.approveAirline(newAirline5, {from: newAirline4});
  result5 = await config.flightSuretyApp.isAirline(newAirline5); 
  assert.equal(result5, false, "fifth airline should not have been approved.");
  await config.flightSuretyApp.approveAirline(newAirline5, {from: newAirline2});
  result5 = await config.flightSuretyApp.isAirline(newAirline5); 
  assert.equal(result5, false, "fifth airline should not have been approved.");
  await config.flightSuretyApp.approveAirline(newAirline5, {from: newAirline3});
  result5 = await config.flightSuretyApp.isAirline(newAirline5); 
  assert.equal(result5, true, "fifth airline should have been approved after 3 approvals.");

    
  });

  // Multiparty Consensus - Airline can be registered, but does not participate in contract until it submits funding of 10 ether
it('Airline can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
    
  // ARRANGE
  let firstAirline = accounts[1];
  let newAirline2 = accounts[2];
  let newAirline3 = accounts[3];
  let newAirline4 = accounts[4];
  let newAirline5 = accounts[5];
  let newAirline6 = accounts[6];
  
  // ACT   
  // For Fifth one. New Airlines have to add themselves. Once Existing Airlines approve by 50% consesus, it would be approved.
  await config.flightSuretyApp.registerAirline(newAirline6, 'Eithad Airlines', {from: newAirline6});

  
  let result6 = await config.flightSuretyApp.isAirline(newAirline6); 
  assert.equal(result6, false, "sixth airline should not have been added.");
  
  //3 votes needed
//Send consesus via approval
await config.flightSuretyApp.approveAirline(newAirline6, {from: newAirline4});
await config.flightSuretyApp.approveAirline(newAirline6, {from: newAirline2});
await config.flightSuretyApp.approveAirline(newAirline6, {from: newAirline3});
result5 = await config.flightSuretyApp.isAirline(newAirline6); 
assert.equal(result5, false, "sixth airline should have been approved since not funded yet.");

  
});
});
