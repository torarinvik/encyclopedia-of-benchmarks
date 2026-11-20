package super_stable_matching_ties_incomplete

import "core:c"

MAX_N :: 4
MAX_PARSEABLE_LENGTH :: 34

solve :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > i64(MAX_N) do return -1
	n := int(n_raw)
	if length != c.size_t(1 + 2*n*n) do return -1

	men_rank: [MAX_N][MAX_N]i64 = {}
	women_rank: [MAX_N][MAX_N]i64 = {}
	for man := 0; man < n; man += 1 {
		for woman := 0; woman < n; woman += 1 {
			rank := input[1 + man*n + woman]
			if rank < 0 || rank > n_raw do return -1
			men_rank[man][woman] = rank
		}
	}
	side := n*n
	for woman := 0; woman < n; woman += 1 {
		for man := 0; man < n; man += 1 {
			rank := input[1 + side + woman*n + man]
			if rank < 0 || rank > n_raw || ((rank > 0) != (men_rank[man][woman] > 0)) do return -1
			women_rank[woman][man] = rank
		}
	}
	for person := 0; person < n; person += 1 {
		maximum := i64(0)
		for partner := 0; partner < n; partner += 1 {
			if men_rank[person][partner] > maximum do maximum = men_rank[person][partner]
		}
		for level := i64(1); level <= maximum; level += 1 {
			found := false
			for partner := 0; partner < n; partner += 1 {
				if men_rank[person][partner] == level do found = true
			}
			if !found do return -1
		}
		maximum = 0
		for partner := 0; partner < n; partner += 1 {
			if women_rank[person][partner] > maximum do maximum = women_rank[person][partner]
		}
		for level := i64(1); level <= maximum; level += 1 {
			found := false
			for partner := 0; partner < n; partner += 1 {
				if women_rank[person][partner] == level do found = true
			}
			if !found do return -1
		}
	}

	alive: [MAX_N][MAX_N]bool = {}
	engaged: [MAX_N][MAX_N]bool = {}
	proposed: [MAX_N]bool = {}
	for man := 0; man < n; man += 1 {
		for woman := 0; woman < n; woman += 1 { alive[man][woman] = men_rank[man][woman] > 0 }
	}
	for {
		proposer := -1
		for man := 0; man < n && proposer < 0; man += 1 {
			has_engagement := false
			has_choice := false
			for woman := 0; woman < n; woman += 1 {
				if engaged[man][woman] do has_engagement = true
				if alive[man][woman] do has_choice = true
			}
			if !has_engagement && has_choice do proposer = man
		}
		if proposer < 0 do break
		head_rank := n_raw + 1
		for woman := 0; woman < n; woman += 1 {
			if alive[proposer][woman] && men_rank[proposer][woman] < head_rank do
				head_rank = men_rank[proposer][woman]
		}
		for woman := 0; woman < n; woman += 1 {
			if !alive[proposer][woman] || men_rank[proposer][woman] != head_rank do continue
			proposed[woman] = true
			engaged[proposer][woman] = true
			for successor := 0; successor < n; successor += 1 {
				if alive[successor][woman] && women_rank[woman][successor] > women_rank[woman][proposer] {
					engaged[successor][woman] = false
					alive[successor][woman] = false
				}
			}
		}
		for woman := 0; woman < n; woman += 1 {
			count := 0
			tail_rank := i64(0)
			for man := 0; man < n; man += 1 {
				if engaged[man][woman] do count += 1
				if alive[man][woman] && women_rank[woman][man] > tail_rank do tail_rank = women_rank[woman][man]
			}
			if count > 1 {
				for man := 0; man < n; man += 1 {
					engaged[man][woman] = false
					if alive[man][woman] && women_rank[woman][man] == tail_rank do alive[man][woman] = false
				}
			}
		}
	}

	base := n_raw + 1
	limit := i64(1)
	for i := 0; i < n; i += 1 do limit *= base
	best_code := i64(0)
	best_size := -1
	for code := i64(0); code < limit; code += 1 {
		used := 0
		size := 0
		valid := true
		place := limit / base
		for man := 0; man < n; man += 1 {
			woman := int((code / place) % base)
			if woman < n {
				if !engaged[man][woman] || (used & (1 << woman)) != 0 do valid = false
				used |= 1 << woman
				size += 1
			}
			if man + 1 < n do place /= base
		}
		if valid && size > best_size {
			best_size = size
			best_code = code
		}
	}
	matched: [MAX_N]bool = {}
	place := limit / base
	for man := 0; man < n; man += 1 {
		woman := int((best_code / place) % base)
		if woman < n do matched[woman] = true
		if man + 1 < n do place /= base
	}
	for woman := 0; woman < n; woman += 1 {
		if proposed[woman] && !matched[woman] do return -2
	}
	return best_code
}

@(export)
super_stable_matching_ties_incomplete :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	return solve(input, length)
}
