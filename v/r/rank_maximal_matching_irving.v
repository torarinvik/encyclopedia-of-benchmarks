module rank_maximal_matching_irving

const max_a = 4
const max_p = 4
const max_v = 8
const max_rank = 4
const max_input = 52
const max_output = 40

fn put64(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn lex_less(left [max_a]int, right [max_a]int, count int) bool {
	for i in 0 .. count { if left[i] != right[i] { return left[i] < right[i] } }
	return false
}

@[export: 'rank_maximal_matching_irving']
pub fn rank_maximal_matching_irving(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		a64, p64, e64 := input[0], input[1], input[2]
		if a64 < 1 || a64 > max_a || p64 < 1 || p64 > max_p { return -1 }
		applicants, posts := int(a64), int(p64)
		if e64 < a64 || e64 > i64(applicants * posts) { return -1 }
		edges := int(e64)
		if edges > 16 || length != usize(3 + 3 * edges) { return -1 }
		mut rank := [max_a][max_p]int{init: 0}
		mut degree := [max_a]int{init: 0}
		mut max_rank_value := 0
		for edge in 0 .. edges {
			at := 3 + 3 * edge
			av, pv, rv := input[at], input[at + 1], input[at + 2]
			if av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > i64(max_rank) { return -1 }
			a, p, r := int(av), int(pv), int(rv)
			if rank[a][p] != 0 { return -1 }
			rank[a][p] = r
			degree[a]++
			if r > max_rank_value { max_rank_value = r }
		}
		for a in 0 .. applicants { if degree[a] == 0 { return -1 } }
		mut blocked := [max_a][max_p]bool{init: false}
		mut mate_a := [max_a]int{init: -1}
		mut mate_p := [max_p]int{init: -1}
		for phase in 1 .. max_rank_value + 1 {
			mut limit := 1
			for _ in 0 .. applicants { limit *= posts + 1 }
			mut best := [max_a]int{init: 0}
			mut best_size := -1
			for code in 0 .. limit {
				mut value := code
				mut candidate := [max_a]int{init: 0}
				mut used, size, valid := 0, 0, true
				for a in 0 .. applicants {
					p := value % (posts + 1)
					value /= posts + 1
					candidate[a] = p
					if p == posts { continue }
					if rank[a][p] == 0 || rank[a][p] > phase || blocked[a][p] || (used & (1 << p)) != 0 { valid = false; break }
					used |= 1 << p
					size++
				}
				if valid && (size > best_size || (size == best_size && lex_less(candidate, best, applicants))) { best_size = size; best = candidate }
			}
			mate_a = [max_a]int{init: -1}
			mate_p = [max_p]int{init: -1}
			for a in 0 .. applicants { if best[a] < posts { mate_a[a] = best[a]; mate_p[best[a]] = a } }
			mut classes := [max_v]int{init: 2}
			mut queue := [max_v]int{init: 0}
			mut head, tail := 0, 0
			for a in 0 .. applicants { if mate_a[a] < 0 { classes[a] = 0; queue[tail] = a; tail++ } }
			for p in 0 .. posts { if mate_p[p] < 0 { v := applicants + p; classes[v] = 0; queue[tail] = v; tail++ } }
			for head < tail {
				v := queue[head]
				head++
				if v < applicants {
					a := v
					if classes[v] == 0 {
						for p in 0 .. posts {
							w := applicants + p
							if rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != p && classes[w] == 2 { classes[w] = 1; queue[tail] = w; tail++ }
						}
					} else if mate_a[a] >= 0 && classes[applicants + mate_a[a]] == 2 { w := applicants + mate_a[a]; classes[w] = 0; queue[tail] = w; tail++ }
				} else {
					p := v - applicants
					if classes[v] == 0 {
						for a in 0 .. applicants { if rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != p && classes[a] == 2 { classes[a] = 1; queue[tail] = a; tail++ } }
					} else if mate_p[p] >= 0 && classes[mate_p[p]] == 2 { a := mate_p[p]; classes[a] = 0; queue[tail] = a; tail++ }
				}
			}
			for a in 0 .. applicants {
				for p in 0 .. posts {
					if rank[a][p] == 0 || blocked[a][p] { continue }
					ca, cp := classes[a], classes[applicants + p]
					if rank[a][p] <= phase {
						if (ca == 1 && cp != 0) || (cp == 1 && ca != 0) { blocked[a][p] = true }
					} else if ca != 0 || cp != 0 { blocked[a][p] = true }
				}
			}
		}
		mut signature := [max_rank]int{init: 0}
		for a in 0 .. applicants { if mate_a[a] >= 0 { signature[rank[a][mate_a[a]] - 1]++ } }
		bytes := 8 * (max_rank_value + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output]u8{init: 0}
		put64(&staged[0], 0, i64(max_rank_value))
		for r in 0 .. max_rank_value { put64(&staged[0], 8 * (r + 1), i64(signature[r])) }
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
