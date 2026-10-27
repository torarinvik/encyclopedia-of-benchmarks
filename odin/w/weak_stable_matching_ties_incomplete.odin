package weak_stable_matching_ties_incomplete

import "core:c"

MAX_N :: 6
MAX_INPUT :: 73
MAX_OUTPUT_BYTES :: 104

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
weak_stable_matching_ties_incomplete :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n, side_size := int(n_raw), int(n_raw*n_raw)
	if length != c.size_t(1+2*side_size) do return -1
	men_rank, women_rank: [MAX_N][MAX_N]i64 = {}, {}
	choices: [MAX_N][MAX_N]int = {}
	choice_count: [MAX_N]int = {}
	for man := 0; man < n; man += 1 { for woman := 0; woman < n; woman += 1 {
		rank := input[1+man*n+woman]
		if rank < 0 || rank > n_raw do return -1
		men_rank[man][woman] = rank
	} }
	for woman := 0; woman < n; woman += 1 { for man := 0; man < n; man += 1 {
		rank := input[1+side_size+woman*n+man]
		if rank < 0 || rank > n_raw || (rank > 0) != (men_rank[man][woman] > 0) do return -1
		women_rank[woman][man] = rank
	} }
	for man := 0; man < n; man += 1 { for woman := 0; woman < n; woman += 1 {
		if men_rank[man][woman] == 0 do continue
		at := choice_count[man]
		for at > 0 {
			prior := choices[man][at-1]
			if men_rank[man][prior] < men_rank[man][woman] || (men_rank[man][prior] == men_rank[man][woman] && prior < woman) do break
			choices[man][at] = prior
			at -= 1
		}
		choices[man][at] = woman
		choice_count[man] += 1
	} }
	man_partner, woman_partner: [MAX_N]int = {}, {}
	next_choice: [MAX_N]int = {}
	for i := 0; i < n; i += 1 { man_partner[i] = -1; woman_partner[i] = -1 }
	for {
		man := -1
		for candidate := 0; candidate < n; candidate += 1 {
			if man_partner[candidate] < 0 && next_choice[candidate] < choice_count[candidate] { man = candidate; break }
		}
		if man < 0 do break
		woman := choices[man][next_choice[man]]
		next_choice[man] += 1
		incumbent := woman_partner[woman]
		if incumbent < 0 || women_rank[woman][man] < women_rank[woman][incumbent] || (women_rank[woman][man] == women_rank[woman][incumbent] && man < incumbent) {
			woman_partner[woman] = man
			man_partner[man] = woman
			if incumbent >= 0 { man_partner[incumbent] = -1 }
		}
	}
	words: [1+2*MAX_N]i64 = {}
	pairs := 0
	for man := 0; man < n; man += 1 { if man_partner[man] >= 0 {
		words[1+2*pairs] = i64(man)
		words[2+2*pairs] = i64(man_partner[man])
		pairs += 1
	} }
	words[0] = i64(pairs)
	output_bytes := 8*(1+2*pairs)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 1+2*pairs; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
