
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
import Web3 from 'web3';

const App = {
    web3Provider: null,
    web3: null,
    accounts: null,
    accountOwner: null,
    contract: null,
  
    start: async function() {

        App.web3 = App.web3Provider;
        App.web3.eth.handleRevert = true
        try {
            // get accounts
            App.accounts = await App.web3.eth.getAccounts();
            App.accountOwner = App.accounts[0];
            console.log('Account Owner: ' + App.accountOwner);
        } catch (error) {
            console.error("Could not connect to contract or chain." + error);
        }
    
        App.contract = new Contract('localhost', App.accountOwner, App.web3);
        var accountInterval = setInterval(async function() {
            let newAccounts = await App.web3.eth.getAccounts();
            let newAccount = newAccounts[0];
          if (newAccount !== App.accountOwner) {
            App.accountOwner = newAccount;
            App.contract.owner = newAccount;
            console.log("new account detected:"+ newAccount);
          }
        }, 100);

            // Read transaction
            App.contract.isOperational((error, result) => {
                console.log(error,result);
                App.display('Operational Status', [ { label: 'Operational Status', error: error, value: result} ]);
            });
    
            App.contract.getApprovedAirlinesCallBack = (error, result) => {
                console.log(error,result);
                
                let airlineOptions = DOM.elid('add-flight-airline-options');
                if(!error && result.length>0)
                {
                    while (airlineOptions.firstChild) {
                        airlineOptions.removeChild(airlineOptions.firstChild);
                    }
                for(let i = 0; i< result.length; i++){
                    let airlineString = result[i];
                    let airlineAddress = airlineString.split("|")[0];
                    let airlineName = airlineString.split("|")[1];
                    let option = document.createElement("option");
                    option.text = airlineName;
                    option.value = airlineAddress;
                    airlineOptions.add(option);
                }
            }};
    
            App.contract.getApprovedAirlines(App.contract.getApprovedAirlinesCallBack);
    
            App.contract.getFlightsAvailableToBuyInsuranceCallBack = (error, result) => {
                console.log(error,result);
                
                let flightOptions = DOM.elid('buy-insurance-flight-number-options');
                if(!error && result.length>0)
                {
                    while (flightOptions.firstChild) {
                        flightOptions.removeChild(flightOptions.firstChild);
                    }
                for(let i = 0; i< result.length; i++){
                    let airlineString = result[i];
                    let airlineName = airlineString.split("|")[0];
                    let flightName = airlineString.split("|")[1];
                    let flightKey = airlineString.split("|")[2];
                    let option = document.createElement("option");
                    option.text = airlineName + " -> " + flightName;
                    option.value = flightKey;
                    flightOptions.add(option);
                }
    
                //oracle-submission-flight-number-options
                let oracleSubmissionFlightOptions = DOM.elid('oracle-submission-flight-number-options');
                if(!error && result.length>0)
                {
                    while (oracleSubmissionFlightOptions.firstChild) {
                        oracleSubmissionFlightOptions.removeChild(oracleSubmissionFlightOptions.firstChild);
                    }
                for(let i = 0; i< result.length; i++){
                    let airlineString = result[i];
                    let airlineName = airlineString.split("|")[0];
                    let flightName = airlineString.split("|")[1];
                    let flightKey = airlineString.split("|")[2];
                    let option = document.createElement("option");
                    option.text = airlineName + " -> " + flightName;
                    option.value = flightKey;
                    oracleSubmissionFlightOptions.add(option);
                }
    
                //view-status-flight-number-options
                let viewStatusFlightOptions = DOM.elid('view-status-flight-number-options');
                if(!error && result.length>0)
                {
                    while (viewStatusFlightOptions.firstChild) {
                        viewStatusFlightOptions.removeChild(viewStatusFlightOptions.firstChild);
                    }
                    for(let i = 0; i< result.length; i++){
                        let airlineString = result[i];
                        let airlineName = airlineString.split("|")[0];
                        let flightName = airlineString.split("|")[1];
                        let flightKey = airlineString.split("|")[2];
                        let option = document.createElement("option");
                        option.text = airlineName + " -> " + flightName;
                        option.value = flightKey;
                        viewStatusFlightOptions.add(option);
                    }
                }
                }
            };
          };
          App.contract.getFlightsAvailableToBuyInsurance(App.contract.getFlightsAvailableToBuyInsuranceCallBack);
        
            // User-submitted transaction
            DOM.elid('add-airline').addEventListener('click', () => {
                let airlineName = DOM.elid('airline-name').value;
                let airlineAddress = DOM.elid('airline-address').value;
                // Write transaction
                App.contract.addAirline(airlineAddress, airlineName, (error, result) => {
                    console.log(error, result);
                    App.display('Airline registration', [ { label: 'Register Airline Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                    App.contract.getApprovedAirlines(App.contract.getApprovedAirlinesCallBack);
                });
            });

            DOM.elid('fund-airline').addEventListener('click', () => {
                let airlineAddress = DOM.elid('fund-airline-airline-address').value;
                // Write transaction
                App.contract.fundAirline(airlineAddress, (error, result) => {
                    console.log(error, result);
                    App.display('Airline Funding', [ { label: 'Fund Airline Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                    App.contract.getApprovedAirlines(App.contract.getApprovedAirlinesCallBack);
                });
            });

    
            DOM.elid('check-credit').addEventListener('click', () => {
                App.contract.checkCredit((error, result) => {
                    console.log(error, result);
                    App.display('Insurance Account', [ { label: 'Check Credit Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                });
            });
    
            DOM.elid('view-status').addEventListener('click', () => {
                let flightKey = DOM.elid('view-status-flight-number-options').value;
                
                App.contract.getFlightStatus(flightKey, (error, result) => {
                    console.log(error, result);
                    App.display('Flight Status', [ { label: 'view Flight Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                    
                });
            });
    
            DOM.elid('withdraw-credit').addEventListener('click', () => {
                let creditsToWithdraw = DOM.elid('withdraw-credit-amount').value;
                // Write transaction
                App.contract.withdrawCredit(creditsToWithdraw, (error, result) => {
                    console.log(error, result);
                    App.display('Insurance Account', [ { label: 'withdraw Credit Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                });
            });
    
            // User-submitted transaction
            DOM.elid('add-flight').addEventListener('click', () => {
                let airlineAddress = DOM.elid('add-flight-airline-options').value;
                let flightNumber = DOM.elid('add-flight-flight-number').value;
                // Write transaction
                App.contract.addFlight(airlineAddress, flightNumber, (error, result) => {
                    console.log(error, result);
                    App.display('Flight Registration', [ { label: 'Register Flight Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                    App.contract.getFlightsAvailableToBuyInsurance(App.contract.getFlightsAvailableToBuyInsuranceCallBack);
                });
            });
    
            // User-submitted transaction
            DOM.elid('buy-insurance').addEventListener('click', () => {
                let flightKey = DOM.elid('buy-insurance-flight-number-options').value;
                let insuranceAmount = DOM.elid('buy-insurance-insurance-amount').value;
                // Write transaction
                App.contract.buyInsurance(flightKey, insuranceAmount, (error, result) => {
                    console.log(error, result);
                    App.display('Insurance Purchase', [ { label: 'buy Insurance Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                });
            });
    
            // User-submitted transaction
            DOM.elid('submit-oracle').addEventListener('click', () => {
                let flightKey = DOM.elid('oracle-submission-flight-number-options').value;
                // Write transaction
                App.contract.submitToOracles(flightKey, (error, result) => {
                    console.log(error, result);
                    App.display('Oracle Submission', [ { label: 'submit to Oracles Status', error: error ? 'There was an error while processing your transaction.': null, value: result} ]);
                });
            });
        
        
        
    
    },
  
    // Implement Task 4 Modify the front end of the DAPP
    display: async function (title, results){
        let displayDiv = DOM.elid("display-wrapper");
        while (displayDiv.firstChild) {
            displayDiv.removeChild(displayDiv.firstChild);
        }
        let section = DOM.section();
        section.appendChild(DOM.h2(title));
        //section.appendChild(DOM.h5(description));
        results.map((result) => {
            let row = section.appendChild(DOM.div({className:'row'}));
            row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
            row.appendChild(DOM.div({className: result.error ? 'text-danger col-sm-8 field-value':'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
            section.appendChild(row);
        })
        displayDiv.append(section);
    }
  
  };
  
  window.App = App;
  
  window.addEventListener("load", async function() {
    if (window.ethereum) {
      // use MetaMask's provider
      App.web3Provider = new Web3(window.ethereum);
        try {
            // Request account access
            await window.ethereum.enable();
        } catch (error) {
            // User denied account access...
            console.error("User denied account access")
        }
    } else if (window.web3) {
        App.web3Provider = window.web3.currentProvider;
    } else {
      console.warn("No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",);
      // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
      App.web3Provider = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"),);
    }
  
    App.start();
  });








