module ranked_matching_popular_matching

const max_a = 4
const max_p = 4
const max_posts = 8
const max_nodes = 12
const max_input = 51
const max_output = 40

fn put64(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

fn lex_less(left [max_a]int, right [max_a]int, count int) bool {
	for index in 0 .. count {
		if left[index] != right[index] { return left[index] < right[index] }
	}
	return false
}

@[export: 'ranked_matching_popular_matching']
pub fn ranked_matching_popular_matching(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > max_input { return -1 }
		a64, p64, e64 := input[0], input[1], input[2]
		if a64 < 1 || a64 > max_a || p64 < 1 || p64 > max_p { return -1 }
		applicants, posts := int(a64), int(p64)
		if e64 < a64 || e64 > i64(applicants * posts) { return -1 }
		edges := int(e64)
		if length != usize(3 + 3 * edges) { return -1 }
		post_count := posts + applicants
		node_count := applicants + post_count
		output_bytes := 8 * (applicants + 1)
		mut rank := [max_a][max_p]i64{init: 0}
		mut rank_seen := [max_a][max_p + 1]bool{init: false}
		mut max_rank := [max_a]int{init: 0}
		for edge in 0 .. edges {
			at := 3 + 3 * edge
			av, pv, rv := input[at], input[at + 1], input[at + 2]
			if av < 0 || av >= a64 || pv < 0 || pv >= p64 || rv < 1 || rv > p64 { return -1 }
			a, p, r := int(av), int(pv), int(rv)
			if rank[a][p] != 0 { return -1 }
			rank[a][p] = rv
			rank_seen[a][r] = true
			if r > max_rank[a] { max_rank[a] = r }
		}
		for a in 0 .. applicants {
			if max_rank[a] == 0 { return -1 }
			for r in 1 .. max_rank[a] + 1 { if !rank_seen[a][r] { return -1 } }
		}
		mut best_m1 := [max_a]int{init: 0}
		mut best_m1_size := -1
		mut m1_limit := 1
		for _ in 0 .. applicants { m1_limit *= posts + 1 }
		for code in 0 .. m1_limit {
			mut value := code
			mut candidate := [max_a]int{init: 0}
			mut used, count, valid := 0, 0, true
			for a in 0 .. applicants {
				p := value % (posts + 1)
				value /= posts + 1
				candidate[a] = p
				if p == posts { continue }
				if rank[a][p] != 1 || (used & (1 << p)) != 0 { valid = false; break }
				used |= 1 << p
				count++
			}
			if valid && (count > best_m1_size || (count == best_m1_size && lex_less(candidate, best_m1, applicants))) {
				best_m1_size = count
				best_m1 = candidate
			}
		}
		mut mate_a := [max_a]int{init: -1}
		mut mate_p := [max_p]int{init: -1}
		for a in 0 .. applicants { if best_m1[a] < posts { mate_a[a] = best_m1[a]; mate_p[best_m1[a]] = a } }
		mut parity := [max_nodes]int{init: -1}
		mut queue := [max_nodes]int{init: 0}
		mut head, tail := 0, 0
		for a in 0 .. applicants { if mate_a[a] < 0 { parity[a] = 0; queue[tail] = a; tail++ } }
		for p in 0 .. posts { if mate_p[p] < 0 { node := applicants + p; parity[node] = 0; queue[tail] = node; tail++ } }
		for p in posts .. post_count { node := applicants + p; parity[node] = 0; queue[tail] = node; tail++ }
		for head < tail {
			node := queue[head]
			head++
			if node < applicants {
				a := node
				if parity[node] == 0 {
					for p in 0 .. posts {
						if rank[a][p] == 1 && mate_a[a] != p && parity[applicants + p] < 0 { parity[applicants + p] = 1; queue[tail] = applicants + p; tail++ }
					}
				} else if mate_a[a] >= 0 && parity[applicants + mate_a[a]] < 0 { parity[applicants + mate_a[a]] = 0; queue[tail] = applicants + mate_a[a]; tail++ }
			} else {
				p := node - applicants
				if p < posts {
					if parity[node] == 0 {
						for a in 0 .. applicants { if rank[a][p] == 1 && mate_a[a] != p && parity[a] < 0 { parity[a] = 1; queue[tail] = a; tail++ } }
					} else if mate_p[p] >= 0 && parity[mate_p[p]] < 0 { parity[mate_p[p]] = 0; queue[tail] = mate_p[p]; tail++ }
				}
			}
		}
		mut class_of := [max_nodes]int{init: 2}
		for n in 0 .. node_count { if parity[n] >= 0 { class_of[n] = parity[n] } }
		mut reduced := [max_a][max_posts]bool{init: false}
		mut allowed := [max_a][max_posts]bool{init: false}
		for a in 0 .. applicants {
			mut best_even_rank := posts + 1
			for p in 0 .. posts {
				if rank[a][p] == 1 { reduced[a][p] = true }
				if rank[a][p] > 0 && class_of[applicants + p] == 0 && int(rank[a][p]) < best_even_rank { best_even_rank = int(rank[a][p]) }
			}
			last_rank := max_rank[a] + 1
			if class_of[applicants + posts + a] == 0 && last_rank < best_even_rank { best_even_rank = last_rank }
			for p in 0 .. posts { if rank[a][p] > 0 && int(rank[a][p]) == best_even_rank && class_of[applicants + p] == 0 { reduced[a][p] = true } }
			if last_rank == best_even_rank && class_of[applicants + posts + a] == 0 { reduced[a][posts + a] = true }
			for p in 0 .. post_count {
				ca, cp := class_of[a], class_of[applicants + p]
				if reduced[a][p] && !((ca == 1 && (cp == 1 || cp == 2)) || (ca == 2 && cp == 1)) { allowed[a][p] = true }
			}
		}
		mut best := [max_a]int{init: 0}
		mut found := false
		mut full_limit := 1
		for _ in 0 .. applicants { full_limit *= post_count }
		for code in 0 .. full_limit {
			mut value := code
			mut candidate := [max_a]int{init: 0}
			mut used, first_count, valid := 0, 0, true
			for a in 0 .. applicants {
				p := value % post_count
				value /= post_count
				candidate[a] = p
				if !allowed[a][p] || (used & (1 << p)) != 0 { valid = false; break }
				used |= 1 << p
				if p < posts && rank[a][p] == 1 { first_count++ }
			}
			if valid && first_count == best_m1_size && (!found || lex_less(candidate, best, applicants)) { found = true; best = candidate }
		}
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output]u8{init: 0}
		put64(&staged[0], 0, if found { i64(1) } else { i64(0) })
		for a in 0 .. applicants { put64(&staged[0], 8 * (a + 1), if found { i64(best[a]) } else { i64(-1) }) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
