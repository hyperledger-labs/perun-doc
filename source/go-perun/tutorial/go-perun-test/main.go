// Copyright (c) 2021, PolyCrypt GmbH, Germany. All rights reserved.
// This file is part of perun-tutorial. Use of this source code is
// governed by the Apache 2.0 license that can be found in the LICENSE file.

package main

import (
	"fmt"
	"time"

	"perun.network/go-perun/client"
)

func main() {
	// Setup Alice and Bob.
	alice, bob := setup(RoleAlice), setup(RoleBob)
	// Run our example protocol: Bob Opens, Updates and Closes.
	if err := bob.openChannel(); err != nil {
		panic(fmt.Errorf("opening channel: %w", err))
	}
	time.Sleep(100 * time.Millisecond) // Wait for Alice to be ready.
	if err := bob.updateChannel(); err != nil {
		panic(fmt.Errorf("updating channel: %w", err))
	}
	if err := bob.closeChannel(); err != nil {
		panic(fmt.Errorf("closing channel: %w", err))
	}
	// Wait for both nodes to stop.
	fmt.Println("Waiting for Alice")
	<-alice.done
	fmt.Println("Waiting for Bob")
	<-bob.done
}

func setup(role Role) *node {
	fmt.Println("Starting ", role)
	account, wallet, err := setupWallet(role)
	if err != nil {
		panic(fmt.Sprintf("setting up wallet: %v", err))
	}
	transactor := createTransactor(wallet)

	_, contractBackend, err := connectToChain(transactor)
	if err != nil {
		panic(fmt.Sprintf("connecting to chain: %v", err))
	}

	adjudicator, assetholder, err := setupContracts(role, contractBackend, account.Account)
	if err != nil {
		panic(fmt.Errorf("setting up contracts: %w", err))
	}

	listener, bus, err := setupNetwork(role, account)
	if err != nil {
		panic(fmt.Errorf("setting up network: %w", err))
	}

	funder := setupFunder(contractBackend, account.Account, assetholder)
	cl, err := client.New(cfg.addrs[role], bus, funder, adjudicator, wallet)
	if err != nil {
		panic(fmt.Errorf("creating client: %w", err))
	}
	// Create the node that defines all event handlers for go-perun.
	node := &node{role: role, account: account, transactor: transactor,
		contractBackend: contractBackend, assetholder: assetholder, listener: listener,
		bus: bus, client: cl, ch: nil, done: make(chan struct{})}
	// Set the NewChannel handler.
	cl.OnNewChannel(node.HandleNewChannel)
	// Start Proposal- and UpdateHandlers.
	go cl.Handle(node, node)
	// Listen on incoming connections.
	go bus.Listen(listener)
	return node
}
