package clock_patience_simulation

import "core:c"

@(export)
clock_patience_simulation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 52 do return -1
	rank_counts: [14]c.size_t
	for index: c.size_t = 0; index < 52; index += 1 {
		rank := values[index]
		if rank < 1 || rank > 13 do return -1
		rank_counts[c.size_t(rank)] += 1
	}
	for rank: c.size_t = 1; rank <= 13; rank += 1 {
		if rank_counts[rank] != 4 do return -1
	}

	next_card: [13]c.size_t
	pile: c.size_t = 12
	revealed: c.size_t = 0
	for next_card[pile] < 4 {
		rank := values[pile * 4 + next_card[pile]]
		next_card[pile] += 1
		revealed += 1
		pile = c.size_t(rank - 1)
	}
	if revealed == 52 do return 1
	return 0
}
