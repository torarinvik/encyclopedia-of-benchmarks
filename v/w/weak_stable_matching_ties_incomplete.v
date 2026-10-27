module weak_stable_matching_ties_incomplete

const (
	max_n = 6
	max_input = 73
	max_output_bytes = 104
)

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'weak_stable_matching_ties_incomplete']
pub fn weak_stable_matching_ties_incomplete(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		n_raw := input[0]
		if n_raw < 1 || n_raw > max_n { return -1 }
		n := int(n_raw)
		side_size := n * n
		if length != 1 + 2 * side_size { return -1 }
		mut men_rank := [max_n][max_n]i64{}
		mut women_rank := [max_n][max_n]i64{}
		mut choices := [max_n][max_n]int{}
		mut choice_count := [max_n]int{}
		for man in 0 .. n { for woman in 0 .. n {
			rank := input[1 + man * n + woman]
			if rank < 0 || rank > n_raw { return -1 }
			men_rank[man][woman] = rank
		} }
		for woman in 0 .. n { for man in 0 .. n {
			rank := input[1 + side_size + woman * n + man]
			if rank < 0 || rank > n_raw || (rank > 0) != (men_rank[man][woman] > 0) { return -1 }
			women_rank[woman][man] = rank
		} }
		for man in 0 .. n { for woman in 0 .. n {
			if men_rank[man][woman] == 0 { continue }
			mut at := choice_count[man]
			for at > 0 {
				prior := choices[man][at - 1]
				if men_rank[man][prior] < men_rank[man][woman] || (men_rank[man][prior] == men_rank[man][woman] && prior < woman) { break }
				choices[man][at] = prior
				at--
			}
			choices[man][at] = woman
			choice_count[man]++
		} }
		mut man_partner := [max_n]int{}
		mut woman_partner := [max_n]int{}
		mut next_choice := [max_n]int{}
		for i in 0 .. n { man_partner[i] = -1; woman_partner[i] = -1 }
		for {
			mut man := -1
			for candidate in 0 .. n {
				if man_partner[candidate] < 0 && next_choice[candidate] < choice_count[candidate] { man = candidate; break }
			}
			if man < 0 { break }
			woman := choices[man][next_choice[man]]
			next_choice[man]++
			incumbent := woman_partner[woman]
			if incumbent < 0 || women_rank[woman][man] < women_rank[woman][incumbent] || (women_rank[woman][man] == women_rank[woman][incumbent] && man < incumbent) {
				woman_partner[woman] = man
				man_partner[man] = woman
				if incumbent >= 0 { man_partner[incumbent] = -1 }
			}
		}
		mut words := [1 + 2 * max_n]i64{}
		mut pairs := 0
		for man in 0 .. n { if man_partner[man] >= 0 {
			words[1 + 2 * pairs] = i64(man)
			words[2 + 2 * pairs] = i64(man_partner[man])
			pairs++
		} }
		words[0] = i64(pairs)
		output_bytes := 8 * (1 + 2 * pairs)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1 + 2 * pairs { put_i64_le(mut staged[0], 8 * word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
