// Bounded clean-room tied-list maximum-cardinality popular matching.
const max_a = 4
const max_p = 4
const max_r = 8
const max_nodes = 12
const max_input = 52

fn mp_augment(a int, right_count int, edges []bool, mut left []int,
	mut right []int, mut seen []bool) bool {
	for p in 0 .. right_count {
		if !edges[a * max_r + p] || seen[p] { continue }
		seen[p] = true
		previous := right[p]
		if previous < 0 || mp_augment(previous, right_count, edges, mut left, mut right, mut seen) {
			right[p] = a
			left[a] = p
			return true
		}
	}
	return false
}

fn mp_maximum(applicants int, right_count int, edges []bool, initial []int,
	mut left []int, mut right []int) bool {
	for a in 0 .. max_a { left[a] = initial[a] }
	for p in 0 .. max_r { right[p] = -1 }
	for a in 0 .. applicants {
		if left[a] >= 0 {
			p := left[a]
			if p >= right_count || right[p] >= 0 || !edges[a * max_r + p] { return false }
			right[p] = a
		}
	}
	for {
		mut changed := false
		for a in 0 .. applicants {
			if left[a] < 0 {
				mut seen := []bool{len: max_r}
				if mp_augment(a, right_count, edges, mut left, mut right, mut seen) { changed = true }
			}
		}
		if !changed { return true }
	}
}

fn mp_solve(applicants int, posts int, ranks []int, max_rank []int) i64 {
	right_count := posts + applicants
	mut first_edges := []bool{len: max_a * max_r}
	for a in 0 .. applicants {
		for p in 0 .. posts { first_edges[a * max_r + p] = ranks[a * max_p + p] == 1 }
	}
	mut initial := []int{len: max_a, init: -1}
	mut first_left := []int{len: max_a}
	mut first_right := []int{len: max_r}
	if !mp_maximum(applicants, right_count, first_edges, initial, mut first_left, mut first_right) { return 0 }
	mut first_size := 0
	for a in 0 .. applicants { if first_left[a] >= 0 { first_size++ } }

	mut state := []int{len: max_nodes, init: -1}
	mut queue := []int{len: max_nodes}
	mut tail := 0
	for a in 0 .. applicants { if first_left[a] < 0 { state[a] = 0; queue[tail] = a; tail++ } }
	for p in 0 .. posts {
		if first_right[p] < 0 { node := applicants + p; state[node] = 0; queue[tail] = node; tail++ }
	}
	for a in 0 .. applicants { node := applicants + posts + a; state[node] = 0; queue[tail] = node; tail++ }
	mut head := 0
	for head < tail {
		node := queue[head]
		head++
		if node < applicants {
			a := node
			if state[node] == 0 {
				for p in 0 .. posts {
					if ranks[a * max_p + p] == 1 && first_left[a] != p {
						target := applicants + p
						if state[target] < 0 { state[target] = 1; queue[tail] = target; tail++ }
					}
				}
			} else if first_left[a] >= 0 {
				target := applicants + first_left[a]
				if state[target] < 0 { state[target] = 0; queue[tail] = target; tail++ }
			}
		} else {
			p := node - applicants
			if p < posts {
				if state[node] == 0 {
					for a in 0 .. applicants {
						if ranks[a * max_p + p] == 1 && first_left[a] != p && state[a] < 0 {
							state[a] = 1; queue[tail] = a; tail++
						}
					}
				} else if first_right[p] >= 0 {
					target := first_right[p]
					if state[target] < 0 { state[target] = 0; queue[tail] = target; tail++ }
				}
			}
		}
	}

	mut classes := []int{len: max_nodes, init: 2}
	for i in 0 .. applicants + right_count { if state[i] >= 0 { classes[i] = state[i] } }
	mut allowed := []bool{len: max_a * max_r}
	for a in 0 .. applicants {
		mut best_even := posts + 1
		for p in 0 .. posts {
			rank := ranks[a * max_p + p]
			if rank > 0 && classes[applicants + p] == 0 && rank < best_even { best_even = rank }
		}
		last_rank := max_rank[a] + 1
		if classes[applicants + posts + a] == 0 && last_rank < best_even { best_even = last_rank }
		for p in 0 .. posts {
			rank := ranks[a * max_p + p]
			if rank != 1 && !(rank > 0 && rank == best_even && classes[applicants + p] == 0) { continue }
			ac, pc := classes[a], classes[applicants + p]
			if (ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1) { continue }
			allowed[a * max_r + p] = true
		}
		if last_rank == best_even && classes[applicants + posts + a] == 0 {
			p := posts + a
			ac, pc := classes[a], classes[applicants + p]
			if !((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) { allowed[a * max_r + p] = true }
		}
	}
	for a in 0 .. applicants { if first_left[a] >= 0 && !allowed[a * max_r + first_left[a]] { return 0 } }

	mut popular_left := []int{len: max_a}
	mut temp_right := []int{len: max_r}
	if !mp_maximum(applicants, right_count, allowed, first_left, mut popular_left, mut temp_right) { return 0 }
	mut rank_one := 0
	for a in 0 .. applicants {
		if popular_left[a] < 0 { return 0 }
		p := popular_left[a]
		if p < posts && ranks[a * max_p + p] == 1 { rank_one++ }
	}
	if rank_one != first_size { return 0 }

	mut real_edges := []bool{len: max_a * max_r}
	mut initial_real := []int{len: max_a, init: -1}
	for a in 0 .. applicants {
		if popular_left[a] < posts { initial_real[a] = popular_left[a] }
		for p in 0 .. posts { real_edges[a * max_r + p] = allowed[a * max_r + p] }
	}
	mut real_left := []int{len: max_a}
	if !mp_maximum(applicants, right_count, real_edges, initial_real, mut real_left, mut temp_right) { return 0 }
	rank_one = 0
	for a in 0 .. applicants {
		p := real_left[a]
		if p >= 0 && p < posts && ranks[a * max_p + p] == 1 { rank_one++ }
	}
	if rank_one != first_size { return 0 }
	mut final_left := []int{len: max_a}
	if !mp_maximum(applicants, right_count, allowed, real_left, mut final_left, mut temp_right) { return 0 }
	mut result := 0
	rank_one = 0
	for a in 0 .. applicants {
		if final_left[a] < 0 { return 0 }
		p := final_left[a]
		if p < posts { result++; if ranks[a * max_p + p] == 1 { rank_one++ } }
	}
	if rank_one != first_size { return 0 }
	return i64(result)
}

@[export: 'ties_maximum_cardinality_popular_matching']
pub fn ties_maximum_cardinality_popular_matching(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		av, pv, ev := input[0], input[1], input[2]
		if av < 1 || av > max_a || pv < 1 || pv > max_p || ev < av || ev > av * pv { return -1 }
		applicants, posts, edge_count := int(av), int(pv), int(ev)
		if length != usize(3 + 3 * edge_count) { return -1 }
		mut ranks := []int{len: max_a * max_p}
		mut max_rank := []int{len: max_a}
		mut cursor := 3
		for _ in 0 .. edge_count {
			a64, p64, r64 := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if a64 < 0 || a64 >= av || p64 < 0 || p64 >= pv || r64 < 1 || r64 > pv { return -1 }
			a, p, rank := int(a64), int(p64), int(r64)
			if ranks[a * max_p + p] != 0 { return -1 }
			ranks[a * max_p + p] = rank
			if rank > max_rank[a] { max_rank[a] = rank }
		}
		mut has_tie := false
		for a in 0 .. applicants {
			if max_rank[a] == 0 { return -1 }
			mut counts := []int{len: max_p + 1}
			for p in 0 .. posts { rank := ranks[a * max_p + p]; if rank > 0 { counts[rank]++ } }
			for rank in 1 .. max_rank[a] + 1 {
				if counts[rank] == 0 { return -1 }
				if counts[rank] > 1 { has_tie = true }
			}
		}
		if !has_tie { return -1 }
		return mp_solve(applicants, posts, ranks, max_rank)
	}
}
