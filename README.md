# ethereum-solidity
Sample code to run smart contract programs on Ethereum platform

## assumption
- running on Linux (your favorite distro)
- running with KVM guests which have Ubuntu installed

## setup                                                
- VMs has enough resources (like 4 vCPUs, 4 GB memory, 30 GB storage)
- you need install to VMs Ethereum environment like below (see also https://github.com/ethereum/go-ethereum/wiki/Installation-Instructions-for-Ubuntu)
```
apt-get -y update                                         
apt-get install -y software-properties-common             
add-apt-repository -y ppa:ethereum/ethereum               
add-apt-repository -y ppa:ethereum/ethereum-dev           
apt-get -y update                                         
apt-get -y install ethereum solc        
```

## how to run                                                     
see comment in Makefile, but typical command is like this:
```                                                             
CONTRACT=<testcase> NODES="srv1 srv2" make run
```                                                             
