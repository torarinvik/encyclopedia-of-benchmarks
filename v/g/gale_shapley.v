module gale_shapley

// Proposer-proposing Gale-Shapley stable matching for complete preferences.
@[export: 'gale_shapley']
pub fn gale_shapley(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > 66 { return -2 }
	unsafe {
		if values[0] < 0 || values[0] > 5 { return -2 }
		count := usize(values[0])
		if length != 1 + 2 * count * count { return -2 }
		mut ranks := [5][5]i64{}
		mut seen := [5]bool{}
		for proposer := usize(0); proposer < count; proposer++ {
			for index := usize(0); index < count; index++ { seen[index] = false }
			for rank := usize(0); rank < count; rank++ {
				accepter := values[1 + proposer * count + rank]
				if accepter < 0 || usize(accepter) >= count || seen[usize(accepter)] { return -2 }
				seen[usize(accepter)] = true
			}
		}
		accepter_offset := 1 + count * count
		for accepter := usize(0); accepter < count; accepter++ {
			for index := usize(0); index < count; index++ { seen[index] = false }
			for rank := usize(0); rank < count; rank++ {
				proposer := values[accepter_offset + accepter * count + rank]
				if proposer < 0 || usize(proposer) >= count || seen[usize(proposer)] { return -2 }
				seen[usize(proposer)] = true
				ranks[accepter][usize(proposer)] = i64(rank)
			}
		}
		if output_capacity < count { return -2 }
		mut matched_proposer := [5]i64{}
		mut matched_accepter := [5]i64{}
		mut next_choice := [5]usize{}
		for index := usize(0); index < count; index++ {
			matched_proposer[index] = -1
			matched_accepter[index] = -1
		}
		for {
			mut proposer := usize(0)
			for proposer < count && matched_accepter[proposer] != -1 { proposer++ }
			if proposer == count { break }
			accepter := usize(values[1 + proposer * count + next_choice[proposer]])
			next_choice[proposer]++
			current := matched_proposer[accepter]
			if current == -1 || ranks[accepter][proposer] < ranks[accepter][usize(current)] {
				if current != -1 { matched_accepter[usize(current)] = -1 }
				matched_proposer[accepter] = i64(proposer)
				matched_accepter[proposer] = i64(accepter)
			}
		}
		for proposer := usize(0); proposer < count; proposer++ {
			output[proposer] = u8(matched_accepter[proposer])
		}
		return i64(count)
	}
}
