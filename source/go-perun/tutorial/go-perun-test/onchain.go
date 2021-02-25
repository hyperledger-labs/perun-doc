// Copyright (c) 2021, PolyCrypt GmbH, Germany. All rights reserved.
// This file is part of perun-tutorial. Use of this source code is
// governed by the Apache 2.0 license that can be found in the LICENSE file.

package main

import (
	"context"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	ethchannel "perun.network/go-perun/backend/ethereum/channel"
)

func connectToChain(transactor ethchannel.Transactor) (client *ethclient.Client, cb ethchannel.ContractBackend, err error) {
	client, err = ethclient.Dial(cfg.chainURL)
	if err != nil {
		return
	}

	return client, ethchannel.NewContractBackend(client, transactor), nil
}

func deployContracts(cb ethchannel.ContractBackend, acc accounts.Account) (adj, ah common.Address, err error) {
	// The context timeout must be atleast twice the blocktime.
	ctx, cancel := context.WithTimeout(context.Background(), 31*time.Second)
	defer cancel()

	adj, err = ethchannel.DeployAdjudicator(ctx, cb, acc)
	if err != nil {
		return
	}

	ah, err = ethchannel.DeployETHAssetholder(ctx, cb, adj, acc)
	return
}

func validateContracts(cb ethchannel.ContractBackend, adj, ah common.Address) error {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	// Assetholder validation includes Adjudicator validation.
	return ethchannel.ValidateAssetHolderETH(ctx, cb, ah, adj)
}

func setupContracts(role Role, contractBackend ethchannel.ContractBackend, account accounts.Account) (adjudicator *ethchannel.Adjudicator, assetholder common.Address, err error) {
	var adjudicatorAddr common.Address
	// Alice will deploy the contracts and Bob validate them.
	if role == RoleAlice {
		adjudicatorAddr, assetholder, err = deployContracts(contractBackend, account)
		fmt.Println("Deployed contracts")
	} else {
		// Assume default addresses for Adjudicator and Assetholder.
		adjudicatorAddr = common.HexToAddress("0x079557d7549d7D44F4b00b51d2C532674129ed51")
		assetholder = common.HexToAddress("0x923439be515b6A928cB9650d70000a9044e49E85")
		err = validateContracts(contractBackend, adjudicatorAddr, assetholder)
		fmt.Println("Validated contracts")
	}
	fmt.Printf(" Adjudicator at %v\n AssetHolder at %v\n", adjudicatorAddr, assetholder)
	adjudicator = ethchannel.NewAdjudicator(contractBackend, adjudicatorAddr, account.Address, account)
	return
}
