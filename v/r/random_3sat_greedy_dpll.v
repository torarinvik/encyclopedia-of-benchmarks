module random_3sat_greedy_dpll

const max_vars = 12
const max_clauses = 32
const max_input = 98
const max_output = 104

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'random_3sat_greedy_dpll']
pub fn random_3sat_greedy_dpll(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_input { return -1 }
	n64 := unsafe { input[0] }
	m64 := unsafe { input[1] }
	if n64 < 3 || n64 > max_vars || m64 < 0 || m64 > max_clauses { return -1 }
	n := int(n64)
	m := int(m64)
	if length != usize(2 + 3 * m) { return -1 }
	mut clauses := [max_clauses][3]int{}
	mut lens := [max_clauses]int{}
	mut active := [max_clauses]bool{}
	for i in 0 .. m {
		mut seen := [max_vars]bool{}
		for j in 0 .. 3 {
			lit := unsafe { input[2 + 3 * i + j] }
			if lit == 0 || lit < -n64 || lit > n64 { return -1 }
			v := int(if lit > 0 { lit } else { -lit }) - 1
			if seen[v] { return -1 }
			seen[v] = true
			clauses[i][j] = int(lit)
		}
		lens[i] = 3
		active[i] = true
	}
	mut assigned := [max_vars]int{}
	mut success := false
	mut failed := false
	for _ in 0 .. n {
		if failed { break }
		mut remaining := 0
		for i in 0 .. m { if active[i] { remaining++ } }
		if remaining == 0 { success = true; break }
		mut chosen := 0
		for i in 0 .. m { if chosen == 0 && active[i] && lens[i] == 1 { chosen = clauses[i][0] } }
		if chosen == 0 {
			mut counts := [2 * max_vars]int{}
			for i in 0 .. m {
				if active[i] { for j in 0 .. lens[i] { lit := clauses[i][j]; v := int(if lit > 0 { lit } else { -lit }) - 1; sign := if lit < 0 { 1 } else { 0 }; counts[2 * v + sign]++ } }
			}
			mut best := 0
			for v in 0 .. n {
				for sign in 0 .. 2 {
					count := counts[2 * v + sign]
					if count > best { best = count; chosen = if sign == 0 { v + 1 } else { -(v + 1) } }
				}
			}
		}
		if chosen == 0 { failed = true; break }
		variable := int(if chosen > 0 { chosen } else { -chosen }) - 1
		assigned[variable] = if chosen > 0 { 1 } else { -1 }
		for i in 0 .. m {
			if active[i] {
				mut satisfied := false
				for j in 0 .. lens[i] { if clauses[i][j] == chosen { satisfied = true } }
				if satisfied { active[i] = false; continue }
				mut write := 0
				for j in 0 .. lens[i] { if clauses[i][j] != -chosen { clauses[i][write] = clauses[i][j]; write++ } }
				lens[i] = write
				if write == 0 { failed = true; break }
			}
		}
	}
	if !failed { mut remaining := 0; for i in 0 .. m { if active[i] { remaining++ } }; success = remaining == 0 }
	if success { for i in 0 .. n { if assigned[i] == 0 { assigned[i] = -1 } } }
	bytes := 8 * (n + 1)
	if output == nil || capacity < usize(bytes) { return -2 }
	mut staged := [max_output]u8{}
	put_i64(mut &staged[0], 0, if success { 1 } else { 0 })
	for i in 0 .. n { put_i64(mut &staged[0], 8 * (i + 1), i64(assigned[i])) }
	for i in 0 .. bytes { unsafe { output[i] = staged[i] } }
	return i64(bytes)
}
