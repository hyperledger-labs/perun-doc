// Copyright (c) 2021, PolyCrypt GmbH, Germany. All rights reserved.
// This file is part of perun-tutorial. Use of this source code is
// governed by the Apache 2.0 license that can be found in the LICENSE file.

package main

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
	ethchannel "perun.network/go-perun/backend/ethereum/channel"
	ethwallet "perun.network/go-perun/backend/ethereum/wallet"
	"perun.network/go-perun/backend/ethereum/wallet/hd"
	"perun.network/go-perun/channel"
	"perun.network/go-perun/client"
	"perun.network/go-perun/wallet"
	"perun.network/go-perun/wire"
	"perun.network/go-perun/wire/net"
)

type node struct {
	role Role

	account         wallet.Account
	transactor      *hd.Transactor
	contractBackend ethchannel.ContractBackend
	assetholder     common.Address
	listener        net.Listener
	bus             *net.Bus
	client          *client.Client
	ch              *client.Channel
	done            chan struct{} // Signals that the channel got closed.
}

func (n *node) openChannel() error {
	fmt.Printf("Opening channel from %v to %v\n", n.role, 1-n.role)
	// Alice and Bob will both start with 10 ETH.
	initBal := ethToWei(10)
	// Perun needs an initial allocation which defines the balances of all
	// participants. The same structure is used for multi-asset channels.
	initBals := &channel.Allocation{
		Assets:   []channel.Asset{ethwallet.AsWalletAddr(n.assetholder)},
		Balances: [][]*big.Int{{initBal, initBal}},
	}
	// All perun identities that we want to open a channel with. In this case
	// we use the same on- and off-chain accounts but you could use different.
	peers := []wire.Address{
		cfg.addrs[n.role],
		cfg.addrs[1-n.role],
	}
	// Prepare the proposal by defining the channel parameters.
	proposal, err := client.NewLedgerChannelProposal(10, cfg.addrs[n.role], initBals, peers)
	if err != nil {
		return fmt.Errorf("creating channel proposal: %w", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	// Send the proposal.
	channel, err := n.client.ProposeChannel(ctx, proposal)
	if err != nil {
		return fmt.Errorf("proposing channel: %w", err)
	}
	fmt.Printf("🎉 Opened channel with id 0x%x \n", channel.ID())
	return nil
}

func (n *node) HandleProposal(_proposal client.ChannelProposal, responder *client.ProposalResponder) {
	// Check that we got a ledger channel proposal.
	proposal, ok := _proposal.(*client.LedgerChannelProposal)
	if !ok {
		fmt.Println("Received a proposal that was not for a ledger channel.")
		return
	}
	// Print the proposers address (his index is always 0).
	fmt.Printf("Received channel proposal from 0x%x\n", proposal.Peers[0])
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	// Create a channel accept message and send it.
	accept := proposal.Accept(n.account.Address(), client.WithRandomNonce())
	channel, err := responder.Accept(ctx, accept)
	if err != nil {
		fmt.Println("Accepting channel: %w\n", err)
	} else {
		fmt.Printf("Accepted channel with id 0x%x\n", channel.ID())
	}
}

func (n *node) HandleNewChannel(ch *client.Channel) {
	fmt.Printf("%v HandleNewChannel with id 0x%x\n", n.role, ch.ID())
	n.ch = ch
	// Start the on-chain watcher.
	go func() {
		err := ch.Watch(n)
		fmt.Println("Watcher returned with: ", err)
		close(n.done)
	}()
}

func (n *node) updateChannel() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	// Use UpdateBy to conveniently update the channels state.
	return n.ch.UpdateBy(ctx, func(state *channel.State) error {
		// Shift 5 ETH from bob to alice.
		amount := ethToWei(5)
		state.Balances[0][RoleBob].Sub(state.Balances[0][RoleBob], amount)
		state.Balances[0][RoleAlice].Add(state.Balances[0][RoleAlice], amount)
		// Finalize the channel, this will be important in the next step.
		state.IsFinal = true
		return nil
	})
}

func (n *node) HandleUpdate(update client.ChannelUpdate, responder *client.UpdateResponder) {
	fmt.Printf("%v HandleUpdate Bals=%s\n", n.role, formatBalances(update.State.Balances))
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := responder.Accept(ctx); err != nil {
		fmt.Printf("Could not accept update: %v\n", err)
	}
}

func formatBalances(bals channel.Balances) string {
	return fmt.Sprintf("[%v, %v]", bals[0][RoleAlice], bals[0][RoleBob])
}

func (n *node) closeChannel() error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	if err := n.ch.Register(ctx); err != nil {
		return fmt.Errorf("registering channel: %w", err)
	}
	if err := n.ch.Settle(ctx, false); err != nil {
		return fmt.Errorf("settling channel: %w", err)
	}
	// .Close() closes the channel object and has nothing to do with the
	// go-perun channel protocol.
	if err := n.ch.Close(); err != nil {
		return fmt.Errorf("closing channel object: %w", err)
	}
	close(n.done)
	return nil
}

func (n *node) HandleAdjudicatorEvent(e channel.AdjudicatorEvent) {
	fmt.Printf("HandleAdjudicatorEvent called id=0x%x\n", e.ID())
	// Alice reacts to a channel closing by doing the same as Bob.
	if _, ok := e.(*channel.ConcludedEvent); ok && n.role == RoleAlice {
		n.closeChannel()
	}
}

func ethToWei(eth float64) *big.Int {
	//1 Ether = 10^18 Wei
	var ethPerWei = new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)
	wei, _ := new(big.Float).Mul(big.NewFloat(eth), new(big.Float).SetInt(ethPerWei)).Int(new(big.Int))
	return wei
}
