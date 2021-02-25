// Copyright (c) 2021, PolyCrypt GmbH, Germany. All rights reserved.
// This file is part of perun-tutorial. Use of this source code is
// governed by the Apache 2.0 license that can be found in the LICENSE file.

package main

import (
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/core/types"
	hdwallet "github.com/miguelmota/go-ethereum-hdwallet"
	perunhd "perun.network/go-perun/backend/ethereum/wallet/hd"
)

func setupWallet(role Role) (*perunhd.Account, *perunhd.Wallet, error) {
	rootWallet, err := hdwallet.NewFromMnemonic(cfg.mnemonic)
	if err != nil {
		return nil, nil, fmt.Errorf("creating hd wallet: %w", err)
	}
	// Alice has account index 0 and Bob 1.
	wallet, err := perunhd.NewWallet(rootWallet, "m/44'/60'/0'/0/0", uint(role))
	if err != nil {
		return nil, nil, fmt.Errorf("deriving path: %w", err)
	}
	// Derive the first account from the wallet.
	acc, err := wallet.NewAccount()
	if err != nil {
		return nil, nil, fmt.Errorf("deriving hd account: %w", err)
	}

	return acc, wallet, nil
}

func createTransactor(wallet *perunhd.Wallet) *perunhd.Transactor {
	// 1337 is the default chain id for ganache-cli.
	signer := types.NewEIP155Signer(big.NewInt(1337))
	return perunhd.NewTransactor(wallet.Wallet(), signer)
}
