import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
const cors = require('cors');


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress, {gasLimit: "10000000"});
var oracles = [
  { address:"0x69e1CB5cFcA8A311586e3406ed0301C06fb839a2", indexes: null},
{ address:"0xF014343BDFFbED8660A9d8721deC985126f189F3", indexes: null},
{ address:"0x0E79EDbD6A727CfeE09A2b1d0A59F7752d5bf7C9", indexes: null},
{ address:"0x9bC1169Ca09555bf2721A5C9eC6D69c8073bfeB4", indexes: null},
{ address:"0xa23eAEf02F9E0338EEcDa8Fdd0A73aDD781b2A86", indexes: null},
{ address:"0xc449a27B106BE1120Bd1Fd62F8166A2F61588eb9", indexes: null},
{ address:"0xF24AE9CE9B62d83059BD849b9F36d3f4792F5081", indexes: null},
{ address:"0xc44B027a94913FB515B19F04CAf515e74AE24FD6", indexes: null},
{ address:"0xcb0236B37Ff19001633E38808bd124b60B1fE1ba", indexes: null},
{ address:"0x715e632C0FE0d07D02fC3d2Cf630d11e1A45C522", indexes: null},
{ address:"0x90FFD070a8333ACB4Ac1b8EBa59a77f9f1001819", indexes: null},
{ address:"0x036945CD50df76077cb2D6CF5293B32252BCe247", indexes: null},
{ address:"0x23f0227FB09D50477331D2BB8519A38a52B9dFAF", indexes: null},
{ address:"0x799759c45265B96cac16b88A7084C068d38aFce9", indexes: null},
{ address:"0xA6BFE07B18Df9E42F0086D2FCe9334B701868314", indexes: null},
{ address:"0x39Ae04B556bbdD73123Bab2d091DCD068144361F", indexes: null},
{ address:"0x068729ec4f46330d9Af83f2f5AF1B155d957BD42", indexes: null},
{ address:"0x9EE19563Df46208d4C1a11c9171216012E9ba2D0", indexes: null},
{ address:"0x04ab41d3d5147c5d2BdC3BcFC5e62539fd7e428B", indexes: null},
{ address:"0xeF264a86495fF640481D7AC16200A623c92D1E37", indexes: null},
{ address:"0x645FdC97c87c437da6b11b72471a703dF3702813", indexes: null},
{ address:"0xbE6f5bF50087332024634d028eCF896C7b482Ab1", indexes: null},
{ address:"0xcE527c7372B73C77F3A349bfBce74a6F5D800d8E", indexes: null},
{ address:"0x21ec0514bfFefF9E0EE317b8c87657E4a30F4Fb2", indexes: null},
{ address:"0xEAA2fc390D0eC1d047dCC1210a9Bf643d12de330", indexes: null},
{ address:"0xC5fa34ECBaF44181f1d144C13FBaEd69e76b80f1", indexes: null},
{ address:"0x4F388EE383f1634d952a5Ed8e032Dc27094f44FD", indexes: null},
{ address:"0xeEf5E3535aA39e0C2266BbA234E187adA9ed50A1", indexes: null},
{ address:"0x6008E128477ceEE5561fE2dEAdD82564d29fD249", indexes: null},
{ address:"0xfEf504C230aA4c42707FcBFfa46aE640498BC2cb", indexes: null},
];



function listenEvents(latestBlockNumber){
  console.log("listening from block number:"+ latestBlockNumber);
  flightSuretyApp.events.FlightStatusInfo({
    fromBlock: latestBlockNumber
  }, function (error, event) {
    if (error) {
      console.log(error)
    }else {
      console.log("FlightStatusInfo Event Received");
      console.log(event);
  }});

  flightSuretyApp.events.OracleReport({
    fromBlock: latestBlockNumber
  }, function (error, event) {
    if (error) {
      console.log(error)
    }else {
      console.log("OracleReport Event Received");
      console.log(event);
  }});

  flightSuretyApp.events.OracleRequest({
    fromBlock: latestBlockNumber
  }, function (error, event) {
    if (error) {
      console.log(error)
    }else {
      console.log("OracleRequest Event Received");
      console.log(event);

      let index = event.returnValues.index;
      let airline = event.returnValues.airline;
      let flight = event.returnValues.flight;
      let timestamp = event.returnValues.timestamp;
      
      for(let j=0; j< oracles.length; j++)
      {

        let statusCode = 0;

        let maximum = 3;
        let minimum = 1;
        var randomnumber = Math.floor(Math.random() * (maximum - minimum + 1)) + minimum;
        // uint8 private constant STATUS_CODE_UNKNOWN = 0;
        // uint8 private constant STATUS_CODE_ON_TIME = 10;
        // uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
        // uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
        // uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
        // uint8 private constant STATUS_CODE_LATE_OTHER = 50;
        if(randomnumber==1){
          statusCode = 10;
        }else if (randomnumber==2){
          statusCode = 20;
        }else{
          statusCode = 0;
        }

        if(oracles[j].indexes== null){
          console.log("indexes has not been set.");
          continue;
        }
        
        if(oracles[j].indexes[0] != index && oracles[j].indexes[1] != index  && oracles[j].indexes[2] != index){
          console.log("indexes did not match." + index + ", indexes:" + oracles[j].indexes);
          continue;
        }

        flightSuretyApp.methods
        .submitOracleResponse(index, airline, flight, timestamp, "20")
        .send({ from: oracles[j].address}, (oracleResponseSubmissionError, result) => {
          if(!oracleResponseSubmissionError)
          {
            console.log(result);
          }else{
            console.log(oracleResponseSubmissionError);
          }
      });
    }
      


    }
});
}

let totalRegisterered = 0;
for(let i=0; i < oracles.length; i++){
  console.log("Registering Oracle@"+ i + "");
  flightSuretyApp.methods
  .registerOracle()
  .send({ from: oracles[i].address, value: '1000000000000000000'}, (error, result) => {
     if(!error)
     { 
      
          
      flightSuretyApp.methods
      .getMyIndexes()
      .call({ from: oracles[i].address}, (indexesError, result) => {
         if(!indexesError)
         {
          totalRegisterered++;
          oracles[i].indexes = result;
          console.log("Oracles@"+ i + ", "+ JSON.stringify(oracles[i]) +"");
          if(totalRegisterered>=oracles.length){
            web3.eth.getBlockNumber().then((latestBlockNumber) => {
              listenEvents(latestBlockNumber);
            });
          }
         }else{
           console.log(indexesError);
         }
      });    
    }else{
      console.log(error);
    }
  });
}



const app = express();
const port = 8001;
  
app.use(cors({
  origin: 'http://localhost:8000'
}));

app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

app.listen(port, () => {
  console.log(`Api running on port:${port}`)
});

export default app;


