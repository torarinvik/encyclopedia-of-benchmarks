package rank_maximal_matching_irving

import "core:c"

MAX_A :: 4
MAX_P :: 4
MAX_V :: 8
MAX_RANK :: 4
MAX_INPUT :: 52
MAX_OUTPUT :: 40

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}

lex_less :: proc(left, right: [MAX_A]int, count: int) -> bool {
	for index := 0; index < count; index += 1 { if left[index] != right[index] { return left[index] < right[index] } }
	return false
}

@(export)
rank_maximal_matching_irving :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	a64, p64, e64 := input[0], input[1], input[2]
	if a64 < 1 || a64 > MAX_A || p64 < 1 || p64 > MAX_P do return -1
	applicants, posts := int(a64), int(p64)
	if e64 < a64 || e64 > i64(applicants*posts) do return -1
	edges := int(e64)
	if edges > 16 || length != c.size_t(3+3*edges) do return -1
	rank: [MAX_A][MAX_P]int
	degree: [MAX_A]int
	max_rank := 0
	for edge := 0; edge < edges; edge += 1 {
		at := 3+3*edge
		av, pv, rv := input[at], input[at+1], input[at+2]
		if av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > MAX_RANK do return -1
		a, p, r := int(av), int(pv), int(rv)
		if rank[a][p] != 0 do return -1
		rank[a][p] = r
		degree[a] += 1
		if r > max_rank { max_rank = r }
	}
	for a := 0; a < applicants; a += 1 { if degree[a] == 0 do return -1 }
	blocked: [MAX_A][MAX_P]bool
	mate_a: [MAX_A]int
	mate_p: [MAX_P]int
	for a := 0; a < MAX_A; a += 1 { mate_a[a] = -1 }
	for p := 0; p < MAX_P; p += 1 { mate_p[p] = -1 }
	for phase := 1; phase <= max_rank; phase += 1 {
		limit := 1
		for _ := 0; _ < applicants; _ += 1 { limit *= posts+1 }
		best: [MAX_A]int
		best_size := -1
		for code := 0; code < limit; code += 1 {
			value := code
			candidate: [MAX_A]int
			used, size, valid := 0, 0, true
			for a := 0; a < applicants; a += 1 {
				p := value%(posts+1); value /= posts+1; candidate[a] = p
				if p == posts { continue }
				if rank[a][p] == 0 || rank[a][p] > phase || blocked[a][p] || (used&(1<<p)) != 0 { valid = false; break }
				used |= 1<<p; size += 1
			}
			if valid && (size > best_size || (size == best_size && lex_less(candidate,best,applicants))) { best_size = size; best = candidate }
		}
		for a := 0; a < MAX_A; a += 1 { mate_a[a] = -1 }
		for p := 0; p < MAX_P; p += 1 { mate_p[p] = -1 }
		for a := 0; a < applicants; a += 1 { if best[a] < posts { mate_a[a] = best[a]; mate_p[best[a]] = a } }

		classes: [MAX_V]int
		for v := 0; v < applicants+posts; v += 1 { classes[v] = 2 }
		queue: [MAX_V]int
		head, tail := 0, 0
		for a := 0; a < applicants; a += 1 { if mate_a[a] < 0 { classes[a] = 0; queue[tail] = a; tail += 1 } }
		for p := 0; p < posts; p += 1 { if mate_p[p] < 0 { v := applicants+p; classes[v] = 0; queue[tail] = v; tail += 1 } }
		for head < tail {
			v := queue[head]; head += 1
			if v < applicants {
				a := v
				if classes[v] == 0 {
					for p := 0; p < posts; p += 1 {
						if rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != p && classes[applicants+p] == 2 { classes[applicants+p] = 1; queue[tail] = applicants+p; tail += 1 }
					}
				} else if mate_a[a] >= 0 && classes[applicants+mate_a[a]] == 2 { classes[applicants+mate_a[a]] = 0; queue[tail] = applicants+mate_a[a]; tail += 1 }
			} else {
				p := v-applicants
				if classes[v] == 0 {
					for a := 0; a < applicants; a += 1 { if rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != p && classes[a] == 2 { classes[a] = 1; queue[tail] = a; tail += 1 } }
				} else if mate_p[p] >= 0 && classes[mate_p[p]] == 2 { classes[mate_p[p]] = 0; queue[tail] = mate_p[p]; tail += 1 }
			}
		}
		for a := 0; a < applicants; a += 1 {
			for p := 0; p < posts; p += 1 {
				if rank[a][p] == 0 || blocked[a][p] { continue }
				ca, cp := classes[a], classes[applicants+p]
				if rank[a][p] <= phase {
					if (ca == 1 && cp != 0) || (cp == 1 && ca != 0) { blocked[a][p] = true }
				} else if ca != 0 || cp != 0 { blocked[a][p] = true }
			}
		}
	}
	signature: [MAX_RANK]i64
	for a := 0; a < applicants; a += 1 { if mate_a[a] >= 0 { signature[rank[a][mate_a[a]]-1] += 1 } }
	output_bytes := 8*(max_rank+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT]u8
	put64(&staged[0], 0, i64(max_rank))
	for r := 0; r < max_rank; r += 1 { put64(&staged[0], 8*(r+1), signature[r]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
