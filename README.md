# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Library and Versions

$ truffle version
Truffle v5.4.3 (core: 5.4.3)
Solidity - ^0.8.6 (solc-js)
Node v14.17.3
Web3.js v1.5.0

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`

`truffle compile`

## Ganache Cli Setup

### run the command below

`ganache-cli -m "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" --gasLimit=0x1fffffffffffff --allowUnlimitedContractSize -e 1000000000 -a 100`

## MetaMask Setup

### connect to localhost:8545
### import the following accounts using the keys below.

#### Private Keys
==================

(0) 0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3

(1) 0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f  (first airline)

(2) 0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1  (second airline)

(3) 0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c  (third airline)

(4) 0x388c684f0ba1ef5017716adb5d21a053ea8e90277d0868337519f97bede61418  (fourth airline)

(5) 0x659cbb0e2411a44db63778987b1e22153c086a95eb6b18bdf89de078917abc63 (fifth airline)

(6) 0x82d052c865f5763aad42add438569276c00d3d88a2d062d36b2bae914d58b8c8 (sixth airline)

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

first airline is registered only but has not been funded. fund the first airline. this will show up in drop down list once you fund it. refresh the page if you do not see it in screen once you fund it.

same applies for others

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

server runs on port 8001. it only listens to events after latest block.

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Steps
#### Fund the first airline (0xf17f52151EbEF6C7334FAD080c5704D77216b732)
#### Reset the account in Metamask if you get nounce error
#### 

