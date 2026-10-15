package gale_shapley

import "core:c"

// Proposer-proposing Gale-Shapley stable matching for complete preferences.
@(export)
gale_shapley :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 66 || values[0] < 0 || values[0] > 5 do return -2
	count := c.size_t(values[0])
	if length != 1 + 2 * count * count do return -2
	ranks: [5][5]i64
	seen: [5]bool
	for i: c.size_t = 0; i < 5; i += 1 {
		seen[i] = false
		for j: c.size_t = 0; j < 5; j += 1 { ranks[i][j] = 0 }
	}
	for proposer: c.size_t = 0; proposer < count; proposer += 1 {
		for index: c.size_t = 0; index < count; index += 1 { seen[index] = false }
		for rank: c.size_t = 0; rank < count; rank += 1 {
			accepter := values[1 + proposer * count + rank]
			if accepter < 0 || u64(accepter) >= u64(count) || seen[c.size_t(accepter)] do return -2
			seen[c.size_t(accepter)] = true
		}
	}
	accepter_offset := 1 + count * count
	for accepter: c.size_t = 0; accepter < count; accepter += 1 {
		for index: c.size_t = 0; index < count; index += 1 { seen[index] = false }
		for rank: c.size_t = 0; rank < count; rank += 1 {
			proposer := values[accepter_offset + accepter * count + rank]
			if proposer < 0 || u64(proposer) >= u64(count) || seen[c.size_t(proposer)] do return -2
			seen[c.size_t(proposer)] = true
			ranks[accepter][c.size_t(proposer)] = i64(rank)
		}
	}
	if output_capacity < count || (count != 0 && output == nil) do return -2
	matched_proposer: [5]i64
	matched_accepter: [5]i64
	next_choice: [5]c.size_t
	for index: c.size_t = 0; index < count; index += 1 {
		matched_proposer[index] = -1
		matched_accepter[index] = -1
		next_choice[index] = 0
	}
	for {
		proposer := c.size_t(0)
		for proposer < count && matched_accepter[proposer] != -1 { proposer += 1 }
		if proposer == count do break
		accepter := c.size_t(values[1 + proposer * count + next_choice[proposer]])
		next_choice[proposer] += 1
		current := matched_proposer[accepter]
		if current == -1 || ranks[accepter][proposer] < ranks[accepter][c.size_t(current)] {
			if current != -1 { matched_accepter[c.size_t(current)] = -1 }
			matched_proposer[accepter] = i64(proposer)
			matched_accepter[proposer] = i64(accepter)
		}
	}
	for proposer: c.size_t = 0; proposer < count; proposer += 1 {
		output[proposer] = u8(matched_accepter[proposer])
	}
	return i64(count)
}
