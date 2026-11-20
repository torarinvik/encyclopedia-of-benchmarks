// Bounded clean-room tied-list maximum-cardinality popular matching.
package ties_maximum_cardinality_popular_matching

import "core:c"

A :: 4
P :: 4
R :: 8
NODES :: 12
INPUT_MAX :: 52

mp_augment :: proc "contextless" (a, right_count: int, edges: ^[32]bool,
        left: ^[4]int, right: ^[8]int, seen: ^[8]bool) -> bool {
	for p := 0; p < right_count; p += 1 {
		if !edges[a * R + p] || seen[p] do continue
		seen[p] = true
		previous := right[p]
		if previous < 0 || mp_augment(previous, right_count, edges, left, right, seen) {
			right[p] = a
			left[a] = p
			return true
		}
	}
	return false
}

mp_maximum :: proc "contextless" (applicants, right_count: int, edges: ^[32]bool,
		initial: [4]int, left: ^[4]int, right: ^[8]int) -> bool {
	for a := 0; a < A; a += 1 { left[a] = initial[a] }
	for p := 0; p < R; p += 1 { right[p] = -1 }
	for a := 0; a < applicants; a += 1 {
		if left[a] >= 0 {
			p := left[a]
			if p >= right_count || right[p] >= 0 || !edges[a * R + p] do return false
			right[p] = a
		}
	}
	for {
		changed := false
		for a := 0; a < applicants; a += 1 {
			if left[a] < 0 {
				seen: [8]bool
				if mp_augment(a, right_count, edges, left, right, &seen) { changed = true }
			}
		}
		if !changed do return true
	}
}

mp_solve :: proc "contextless" (applicants, posts: int, ranks: [16]int,
		max_rank: [4]int) -> i64 {
	right_count := posts + applicants
	first_edges: [32]bool
	for a := 0; a < applicants; a += 1 {
		for p := 0; p < posts; p += 1 { first_edges[a * R + p] = ranks[a * P + p] == 1 }
	}
	initial: [4]int
	for a := 0; a < A; a += 1 { initial[a] = -1 }
	first_left: [4]int
	first_right: [8]int
	if !mp_maximum(applicants, right_count, &first_edges, initial, &first_left, &first_right) do return 0
	first_size := 0
	for a := 0; a < applicants; a += 1 { if first_left[a] >= 0 do first_size += 1 }

	state: [12]int
	for i := 0; i < applicants + right_count; i += 1 { state[i] = -1 }
	queue: [12]int
	tail := 0
	for a := 0; a < applicants; a += 1 {
		if first_left[a] < 0 { state[a] = 0; queue[tail] = a; tail += 1 }
	}
	for p := 0; p < posts; p += 1 {
		if first_right[p] < 0 { node := applicants + p; state[node] = 0; queue[tail] = node; tail += 1 }
	}
	for a := 0; a < applicants; a += 1 {
		node := applicants + posts + a; state[node] = 0; queue[tail] = node; tail += 1
	}
	for head := 0; head < tail; head += 1 {
		node := queue[head]
		if node < applicants {
			a := node
			if state[node] == 0 {
				for p := 0; p < posts; p += 1 {
					if ranks[a * P + p] == 1 && first_left[a] != p {
						target := applicants + p
						if state[target] < 0 { state[target] = 1; queue[tail] = target; tail += 1 }
					}
				}
			} else if first_left[a] >= 0 {
				target := applicants + first_left[a]
				if state[target] < 0 { state[target] = 0; queue[tail] = target; tail += 1 }
			}
		} else {
			p := node - applicants
			if p < posts {
				if state[node] == 0 {
					for a := 0; a < applicants; a += 1 {
						if ranks[a * P + p] == 1 && first_left[a] != p && state[a] < 0 {
							state[a] = 1; queue[tail] = a; tail += 1
						}
					}
				} else if first_right[p] >= 0 {
					target := first_right[p]
					if state[target] < 0 { state[target] = 0; queue[tail] = target; tail += 1 }
				}
			}
		}
	}

	classes: [12]int
	for i := 0; i < applicants + right_count; i += 1 { classes[i] = 2; if state[i] >= 0 do classes[i] = state[i] }
	allowed: [32]bool
	for a := 0; a < applicants; a += 1 {
		best_even := posts + 1
		for p := 0; p < posts; p += 1 {
			rank := ranks[a * P + p]
			if rank > 0 && classes[applicants + p] == 0 && rank < best_even do best_even = rank
		}
		last_rank := max_rank[a] + 1
		if classes[applicants + posts + a] == 0 && last_rank < best_even do best_even = last_rank
		for p := 0; p < posts; p += 1 {
			rank := ranks[a * P + p]
			if rank != 1 && !(rank > 0 && rank == best_even && classes[applicants + p] == 0) do continue
			ac, pc := classes[a], classes[applicants + p]
			if (ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1) do continue
			allowed[a * R + p] = true
		}
		if last_rank == best_even && classes[applicants + posts + a] == 0 {
			p := posts + a
			ac, pc := classes[a], classes[applicants + p]
			if !((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) do allowed[a * R + p] = true
		}
	}
	for a := 0; a < applicants; a += 1 {
		if first_left[a] >= 0 && !allowed[a * R + first_left[a]] do return 0
	}
	popular_left: [4]int
	temp_right: [8]int
	if !mp_maximum(applicants, right_count, &allowed, first_left, &popular_left, &temp_right) do return 0
	rank_one := 0
	for a := 0; a < applicants; a += 1 {
		if popular_left[a] < 0 do return 0
		p := popular_left[a]
		if p < posts && ranks[a * P + p] == 1 do rank_one += 1
	}
	if rank_one != first_size do return 0

	real_edges: [32]bool
	initial_real: [4]int
	for a := 0; a < A; a += 1 { initial_real[a] = -1 }
	for a := 0; a < applicants; a += 1 {
		if popular_left[a] < posts do initial_real[a] = popular_left[a]
		for p := 0; p < posts; p += 1 { real_edges[a * R + p] = allowed[a * R + p] }
	}
	real_left: [4]int
	if !mp_maximum(applicants, right_count, &real_edges, initial_real, &real_left, &temp_right) do return 0
	rank_one = 0
	for a := 0; a < applicants; a += 1 {
		p := real_left[a]
		if p >= 0 && p < posts && ranks[a * P + p] == 1 do rank_one += 1
	}
	if rank_one != first_size do return 0
	final_left: [4]int
	if !mp_maximum(applicants, right_count, &allowed, real_left, &final_left, &temp_right) do return 0
	result := 0
	rank_one = 0
	for a := 0; a < applicants; a += 1 {
		p := final_left[a]
		if p < 0 do return 0
		if p < posts { result += 1; if ranks[a * P + p] == 1 do rank_one += 1 }
	}
	if rank_one != first_size do return 0
	return i64(result)
}

@(export)
ties_maximum_cardinality_popular_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(INPUT_MAX) do return -1
	av, pv, ev := input[0], input[1], input[2]
	if av < 1 || av > A || pv < 1 || pv > P || ev < av || ev > av * pv do return -1
	applicants, posts, edge_count := int(av), int(pv), int(ev)
	if length != c.size_t(3 + 3 * edge_count) do return -1
	ranks: [16]int
	max_rank: [4]int
	cursor := 3
	for i := 0; i < edge_count; i += 1 {
		a64, p64, r64 := input[cursor], input[cursor + 1], input[cursor + 2]
		cursor += 3
		if a64 < 0 || a64 >= av || p64 < 0 || p64 >= pv || r64 < 1 || r64 > pv do return -1
		a, p, rank := int(a64), int(p64), int(r64)
		if ranks[a * P + p] != 0 do return -1
		ranks[a * P + p] = rank
		if rank > max_rank[a] do max_rank[a] = rank
	}
	has_tie := false
	for a := 0; a < applicants; a += 1 {
		if max_rank[a] == 0 do return -1
		counts: [5]int
		for p := 0; p < posts; p += 1 { rank := ranks[a * P + p]; if rank > 0 do counts[rank] += 1 }
		for rank := 1; rank <= max_rank[a]; rank += 1 {
			if counts[rank] == 0 do return -1
			if counts[rank] > 1 do has_tie = true
		}
	}
	if !has_tie do return -1
	return mp_solve(applicants, posts, ranks, max_rank)
}
