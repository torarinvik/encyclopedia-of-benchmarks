module schuler_randomized_general_cnf_sat

const max_n = 6
const max_m = 4
const max_calls = max_n + 1
const max_input = 122

struct Formula { lengths [4]int; literals [24]i64 }
struct Stats { calls i64; units i64; guesses i64; max_depth i64 }

fn lit_var(lit i64) int { return int(if lit > 0 { lit } else { -lit }) - 1 }
fn lit_true(lit i64, value int) bool { return if lit > 0 { value == 1 } else { value == 0 } }
fn prefix_size(m int) int {
	mut bits := 0
	mut count := m
	for count > 0 { bits++; count >>= 1 }
	return bits + 1
}
fn copy_clause(mut target &Formula, target_clause int, source Formula, source_clause int, count int) {
	target.lengths[target_clause] = count
	for j in 0 .. count { target.literals[target_clause * max_n + j] = source.literals[source_clause * max_n + j] }
}
fn ppz(n int, m int, formula Formula, lengths [4]int, fixed [6]int,
	permutation [6]int, bits [6]int, mut stats &Stats) (bool, [6]int) {
	mut active := [6]int{}
	mut active_count := 0
	mut local := [6]int{}
	for v in 0 .. max_n { local[v] = -1 }
	for i in 0 .. n {
		v := permutation[i] - 1
		if fixed[v] < 0 { active[active_count] = v; active_count++ }
	}
	mut work := formula
	mut work_lengths := lengths
	mut work_m := m
	for offset in 0 .. active_count {
		v := active[offset]
		mut pos_unit := false
		mut neg_unit := false
		for c in 0 .. work_m {
			if work_lengths[c] == 1 {
				lit := work.literals[c * max_n]
				pos_unit = pos_unit || lit == i64(v + 1)
				neg_unit = neg_unit || lit == -i64(v + 1)
			}
		}
		mut value := 0
		if pos_unit { value = 1; stats.units++ } else if neg_unit { stats.units++ } else { value = bits[offset]; stats.guesses++ }
		local[v] = value
		mut next := Formula{}
		mut next_m := 0
		for c in 0 .. work_m {
			mut satisfied := false
			mut kept := 0
			for j in 0 .. work_lengths[c] {
				lit := work.literals[c * max_n + j]
				if lit_var(lit) != v { next.literals[next_m * max_n + kept] = lit; kept++ }
				else if lit_true(lit, value) { satisfied = true; break }
			}
			if !satisfied { next.lengths[next_m] = kept; next_m++ }
		}
		work = next
		work_lengths = next.lengths
		work_m = next_m
	}
	for c in 0 .. work_m { if work_lengths[c] == 0 { return false, local } }
	return true, local
}
fn restrict_formula(formula Formula, lengths [4]int, m int, fixed [6]int) (Formula, int) {
	mut next := Formula{}
	mut next_m := 0
	for c in 0 .. m {
		mut satisfied := false
		mut kept := 0
		for j in 0 .. lengths[c] {
			lit := formula.literals[c * max_n + j]
			value := fixed[lit_var(lit)]
			if value < 0 { next.literals[next_m * max_n + kept] = lit; kept++ }
			else if lit_true(lit, value) { satisfied = true; break }
		}
		if !satisfied { next.lengths[next_m] = kept; next_m++ }
	}
	return next, next_m
}
fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'schuler_randomized_general_cnf_sat']
pub fn schuler_randomized_general_cnf_sat(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_input { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 1 || n0 > max_n || m0 < 1 || m0 > max_m { return -1 }
		n, m := int(n0), int(m0)
		mut formula := Formula{}
		mut at := 2
		for c in 0 .. m {
			if at >= int(length) { return -1 }
			count0 := input[at]; at++
			if count0 < 1 || count0 > n0 || at + int(count0) > int(length) { return -1 }
			mut seen := [6]bool{}
			formula.lengths[c] = int(count0)
			for j in 0 .. int(count0) {
				lit := input[at]; at++
				if lit == 0 || lit < -n0 || lit > n0 { return -1 }
				v := lit_var(lit)
				if seen[v] { return -1 }
				seen[v] = true
				formula.literals[c * max_n + j] = lit
			}
		}
		mut permutations := [max_calls][max_n]int{}
		mut random_bits := [max_calls][max_n]int{}
		mut choices := [max_calls]int{}
		for call in 0 .. n + 1 {
			mut seen := [6]bool{}
			for j in 0 .. n {
				if at >= int(length) { return -1 }
				v := input[at]; at++
				if v < 1 || v > n0 || seen[int(v) - 1] { return -1 }
				seen[int(v) - 1] = true
				permutations[call][j] = int(v)
			}
			for j in 0 .. n {
				if at >= int(length) || (input[at] != 0 && input[at] != 1) { return -1 }
				random_bits[call][j] = int(input[at]); at++
			}
			if at >= int(length) { return -1 }
			choice := input[at]; at++
			if choice < 0 || choice >= m0 { return -1 }
			choices[call] = int(choice)
		}
		if at != int(length) { return -1 }
		mut fixed := [6]int{}
		for v in 0 .. max_n { fixed[v] = -1 }
		mut current := formula
		mut current_lengths := formula.lengths
		mut current_m := m
		mut stats := Stats{}
		mut found := false
		mut mask := i64(0)
		mut depth := 0
		for {
			stats.calls++
			if i64(depth) > stats.max_depth { stats.max_depth = i64(depth) }
			if current_m == 0 {
				found = true
				for v in 0 .. n { if fixed[v] == 1 { mask |= i64(1) << v } }
				break
			}
			k := prefix_size(current_m)
			mut shortened := Formula{}
			for c in 0 .. current_m {
				limit := if current_lengths[c] < k { current_lengths[c] } else { k }
				copy_clause(mut shortened, c, current, c, limit)
			}
			(success, local) := ppz(n, current_m, shortened, shortened.lengths, fixed, permutations[depth], random_bits[depth], mut stats)
			if success {
				found = true
				for v in 0 .. n { if fixed[v] == 1 || (fixed[v] < 0 && local[v] == 1) { mask |= i64(1) << v } }
				break
			}
			mut eligible := [4]int{}
			mut eligible_count := 0
			for c in 0 .. current_m { if shortened.lengths[c] == k { eligible[eligible_count] = c; eligible_count++ } }
			if eligible_count == 0 { break }
			if choices[depth] >= eligible_count { return -1 }
			selected := eligible[choices[depth]]
			mut next_fixed := fixed
			for j in 0 .. k {
				lit := shortened.literals[selected * max_n + j]
				next_fixed[lit_var(lit)] = if lit > 0 { 0 } else { 1 }
			}
			restricted := restrict_formula(current, current_lengths, current_m, next_fixed)
			current = restricted.0
			current_m = restricted.1
			current_lengths = current.lengths
			fixed = next_fixed
			depth++
			if depth > n { return -1 }
		}
		if !found { mask = 0 }
		if output == nil || capacity < 48 { return -2 }
		put_i64(mut output, 0, if found { 1 } else { 0 })
		put_i64(mut output, 1, mask)
		put_i64(mut output, 2, stats.calls)
		put_i64(mut output, 3, stats.units)
		put_i64(mut output, 4, stats.guesses)
		put_i64(mut output, 5, stats.max_depth)
		return 48
	}
}
