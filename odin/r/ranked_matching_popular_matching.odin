package ranked_matching_popular_matching

import "core:c"

MAX_A :: 4
MAX_P :: 4
MAX_POSTS :: 8
MAX_NODES :: 12
MAX_INPUT :: 51
MAX_OUTPUT :: 40

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}

lex_less :: proc(left, right: [MAX_A]int, count: int) -> bool {
	for index := 0; index < count; index += 1 {
		if left[index] != right[index] { return left[index] < right[index] }
	}
	return false
}

@(export)
ranked_matching_popular_matching :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT do return -1
	a64, p64, e64 := input[0], input[1], input[2]
	if a64 < 1 || a64 > MAX_A || p64 < 1 || p64 > MAX_P do return -1
	applicants, posts := int(a64), int(p64)
	if e64 < a64 || e64 > i64(applicants*posts) do return -1
	edges := int(e64)
	if length != c.size_t(3+3*edges) do return -1
	post_count := posts + applicants
	node_count := applicants + post_count
	output_bytes := 8 * (applicants+1)
	rank: [MAX_A][MAX_P]i64
	rank_seen: [MAX_A][MAX_P+1]bool
	max_rank: [MAX_A]int
	for edge := 0; edge < edges; edge += 1 {
		at := 3+3*edge
		av, pv, rv := input[at], input[at+1], input[at+2]
		if av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > p64 do return -1
		a, p, r := int(av), int(pv), int(rv)
		if rank[a][p] != 0 do return -1
		rank[a][p] = rv
		rank_seen[a][r] = true
		if r > max_rank[a] { max_rank[a] = r }
	}
	for a := 0; a < applicants; a += 1 {
		if max_rank[a] == 0 do return -1
		for r := 1; r <= max_rank[a]; r += 1 { if !rank_seen[a][r] do return -1 }
	}

	best_m1: [MAX_A]int
	best_m1_size := -1
	m1_limit := 1
	for _ := 0; _ < applicants; _ += 1 { m1_limit *= posts+1 }
	for code := 0; code < m1_limit; code += 1 {
		value := code
		candidate: [MAX_A]int
		used, count, valid := 0, 0, true
		for a := 0; a < applicants; a += 1 {
			p := value % (posts+1)
			value /= posts+1
			candidate[a] = p
			if p == posts { continue }
			if rank[a][p] != 1 || (used & (1 << p)) != 0 { valid = false; break }
			used |= 1 << p
			count += 1
		}
		if valid && (count > best_m1_size || (count == best_m1_size && lex_less(candidate,best_m1,applicants))) {
			best_m1_size = count
			best_m1 = candidate
		}
	}

	mate_a: [MAX_A]int
	mate_p: [MAX_P]int
	for a := 0; a < applicants; a += 1 { mate_a[a] = -1 }
	for p := 0; p < posts; p += 1 { mate_p[p] = -1 }
	for a := 0; a < applicants; a += 1 {
		if best_m1[a] < posts { mate_a[a] = best_m1[a]; mate_p[best_m1[a]] = a }
	}
	parity: [MAX_NODES]int
	for n := 0; n < node_count; n += 1 { parity[n] = -1 }
	queue: [MAX_NODES]int
	head, tail := 0, 0
	for a := 0; a < applicants; a += 1 {
		if mate_a[a] < 0 { parity[a] = 0; queue[tail] = a; tail += 1 }
	}
	for p := 0; p < posts; p += 1 {
		if mate_p[p] < 0 { node := applicants+p; parity[node] = 0; queue[tail] = node; tail += 1 }
	}
	for p := posts; p < post_count; p += 1 { node := applicants+p; parity[node] = 0; queue[tail] = node; tail += 1 }
	for head < tail {
		node := queue[head]; head += 1
		if node < applicants {
			a := node
			if parity[node] == 0 {
				for p := 0; p < posts; p += 1 {
					if rank[a][p] == 1 && mate_a[a] != p && parity[applicants+p] < 0 {
						parity[applicants+p] = 1; queue[tail] = applicants+p; tail += 1
					}
				}
			} else if mate_a[a] >= 0 && parity[applicants+mate_a[a]] < 0 {
				parity[applicants+mate_a[a]] = 0; queue[tail] = applicants+mate_a[a]; tail += 1
			}
		} else {
			p := node-applicants
			if p < posts {
				if parity[node] == 0 {
					for a := 0; a < applicants; a += 1 {
						if rank[a][p] == 1 && mate_a[a] != p && parity[a] < 0 { parity[a] = 1; queue[tail] = a; tail += 1 }
					}
				} else if mate_p[p] >= 0 && parity[mate_p[p]] < 0 {
					parity[mate_p[p]] = 0; queue[tail] = mate_p[p]; tail += 1
				}
			}
		}
	}
	class_of: [MAX_NODES]int
	for n := 0; n < node_count; n += 1 { class_of[n] = parity[n]; if parity[n] < 0 { class_of[n] = 2 } }
	reduced: [MAX_A][MAX_POSTS]bool
	allowed: [MAX_A][MAX_POSTS]bool
	for a := 0; a < applicants; a += 1 {
		best_even_rank := posts+1
		for p := 0; p < posts; p += 1 {
			if rank[a][p] == 1 { reduced[a][p] = true }
			if rank[a][p] > 0 && class_of[applicants+p] == 0 && int(rank[a][p]) < best_even_rank { best_even_rank = int(rank[a][p]) }
		}
		last_rank := max_rank[a]+1
		if class_of[applicants+posts+a] == 0 && last_rank < best_even_rank { best_even_rank = last_rank }
		for p := 0; p < posts; p += 1 {
			if rank[a][p] > 0 && int(rank[a][p]) == best_even_rank && class_of[applicants+p] == 0 { reduced[a][p] = true }
		}
		if last_rank == best_even_rank && class_of[applicants+posts+a] == 0 { reduced[a][posts+a] = true }
		for p := 0; p < post_count; p += 1 {
			ca, cp := class_of[a], class_of[applicants+p]
			if reduced[a][p] && !((ca == 1 && (cp == 1 || cp == 2)) || (ca == 2 && cp == 1)) { allowed[a][p] = true }
		}
	}
	best: [MAX_A]int
	found := false
	full_limit := 1
	for _ := 0; _ < applicants; _ += 1 { full_limit *= post_count }
	for code := 0; code < full_limit; code += 1 {
		value := code
		candidate: [MAX_A]int
		used, first_count, valid := 0, 0, true
		for a := 0; a < applicants; a += 1 {
			p := value%post_count; value /= post_count; candidate[a] = p
			if !allowed[a][p] || (used & (1<<p)) != 0 { valid = false; break }
			used |= 1<<p
			if p < posts && rank[a][p] == 1 { first_count += 1 }
		}
		if valid && first_count == best_m1_size && (!found || lex_less(candidate,best,applicants)) { found = true; best = candidate }
	}
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT]u8
	status: i64 = 0
	if found { status = 1 }
	put64(&staged[0], 0, status)
	for a := 0; a < applicants; a += 1 { value: i64 = -1; if found { value = i64(best[a]) }; put64(&staged[0], 8*(a+1), value) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
