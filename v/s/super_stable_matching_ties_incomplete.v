module super_stable_matching_ties_incomplete

const max_n = 4
const max_parseable_length = 34

fn solve(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		n_raw := input[0]
		if n_raw < 1 || n_raw > max_n { return -1 }
		n := int(n_raw)
		if length != usize(1 + 2*n*n) { return -1 }
		side := n*n
		mut men_rank := [max_n][max_n]i64{}
		mut women_rank := [max_n][max_n]i64{}
		for man in 0 .. n {
			for woman in 0 .. n {
				rank := input[1 + man*n + woman]
				if rank < 0 || rank > n_raw { return -1 }
				men_rank[man][woman] = rank
			}
		}
		for woman in 0 .. n {
			for man in 0 .. n {
				rank := input[1 + side + woman*n + man]
				if rank < 0 || rank > n_raw || ((rank > 0) != (men_rank[man][woman] > 0)) { return -1 }
				women_rank[woman][man] = rank
			}
		}
		for person in 0 .. n {
			mut maximum := i64(0)
			for partner in 0 .. n { if men_rank[person][partner] > maximum { maximum = men_rank[person][partner] } }
			for level := i64(1); level <= maximum; level++ {
				mut found := false
				for partner in 0 .. n { if men_rank[person][partner] == level { found = true } }
				if !found { return -1 }
			}
			maximum = 0
			for partner in 0 .. n { if women_rank[person][partner] > maximum { maximum = women_rank[person][partner] } }
			for level := i64(1); level <= maximum; level++ {
				mut found := false
				for partner in 0 .. n { if women_rank[person][partner] == level { found = true } }
				if !found { return -1 }
			}
		}

		mut alive := [max_n][max_n]bool{}
		mut engaged := [max_n][max_n]bool{}
		mut proposed := [max_n]bool{}
		for man in 0 .. n { for woman in 0 .. n { alive[man][woman] = men_rank[man][woman] > 0 } }
		for {
			mut proposer := -1
			for man in 0 .. n {
				mut has_engagement := false
				mut has_choice := false
				for woman in 0 .. n {
					if engaged[man][woman] { has_engagement = true }
					if alive[man][woman] { has_choice = true }
				}
				if proposer < 0 && !has_engagement && has_choice { proposer = man }
			}
			if proposer < 0 { break }
			mut head_rank := n_raw + 1
			for woman in 0 .. n {
				if alive[proposer][woman] && men_rank[proposer][woman] < head_rank {
					head_rank = men_rank[proposer][woman]
				}
			}
			for woman in 0 .. n {
				if !alive[proposer][woman] || men_rank[proposer][woman] != head_rank { continue }
				proposed[woman] = true
				engaged[proposer][woman] = true
				for successor in 0 .. n {
					if alive[successor][woman] && women_rank[woman][successor] > women_rank[woman][proposer] {
						engaged[successor][woman] = false
						alive[successor][woman] = false
					}
				}
			}
			for woman in 0 .. n {
				mut count := 0
				mut tail_rank := i64(0)
				for man in 0 .. n {
					if engaged[man][woman] { count++ }
					if alive[man][woman] && women_rank[woman][man] > tail_rank { tail_rank = women_rank[woman][man] }
				}
				if count > 1 {
					for man in 0 .. n {
						engaged[man][woman] = false
						if alive[man][woman] && women_rank[woman][man] == tail_rank { alive[man][woman] = false }
					}
				}
			}
		}

		base := n_raw + 1
		mut limit := i64(1)
		for _ in 0 .. n { limit *= base }
		mut best_code := i64(0)
		mut best_size := -1
		for code := i64(0); code < limit; code++ {
			mut used := 0
			mut size := 0
			mut valid := true
			mut place := limit / base
			for man in 0 .. n {
				woman := int((code / place) % base)
				if woman < n {
					if !engaged[man][woman] || (used & (1 << woman)) != 0 { valid = false }
					used |= 1 << woman
					size++
				}
				if man + 1 < n { place /= base }
			}
			if valid && size > best_size { best_size = size; best_code = code }
		}
		mut matched := [max_n]bool{}
		mut place := limit / base
		for man in 0 .. n {
			woman := int((best_code / place) % base)
			if woman < n { matched[woman] = true }
			if man + 1 < n { place /= base }
		}
		for woman in 0 .. n { if proposed[woman] && !matched[woman] { return -2 } }
		return best_code
	}
}

@[export: 'super_stable_matching_ties_incomplete']
pub fn super_stable_matching_ties_incomplete(input &i64, length usize) i64 {
	return solve(input, length)
}
