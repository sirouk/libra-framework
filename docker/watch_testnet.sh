#!/bin/bash

apt update && apt install -y jq curl

echo "\nAlice Info:"; 
echo "\n\t Connections:"; curl -s 127.0.0.1:9201/metrics | grep "_connections"; 
echo "\n\t Version:"; curl -s 127.0.0.1:8280/v1 | jq .ledger_version; 

echo "\nBob Info:"; 
echo "\n\t Connections:"; curl -s 127.0.0.1:9301/metrics | grep "_connections"; 
echo "\n\t Version:"; curl -s 127.0.0.1:8380/v1 | jq .ledger_version; 

echo "\nCarol Info:"; 
echo "\n\t Connections:"; curl -s 127.0.0.1:9401/metrics | grep "_connections"; 
echo "\n\t Version:"; curl -s 127.0.0.1:8480/v1 | jq .ledger_version; 
