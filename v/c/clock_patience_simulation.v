module clock_patience_simulation

@[export: 'clock_patience_simulation']
pub fn clock_patience_simulation(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length != 52 { return -1 }
		mut rank_counts := [14]int{}
		for index := usize(0); index < 52; index++ {
			rank := values[index]
			if rank < 1 || rank > 13 { return -1 }
			rank_counts[int(rank)]++
		}
		for rank := 1; rank <= 13; rank++ {
			if rank_counts[rank] != 4 { return -1 }
		}

		mut next_card := [13]int{}
		mut pile := 12
		mut revealed := 0
		for next_card[pile] < 4 {
			rank := values[pile * 4 + next_card[pile]]
			next_card[pile]++
			revealed++
			pile = int(rank - 1)
		}
		return if revealed == 52 { 1 } else { 0 }
	}
}
