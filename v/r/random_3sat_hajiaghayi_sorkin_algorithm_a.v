module random_3sat_hajiaghayi_sorkin_algorithm_a

const max_vars = 12
const max_clauses = 32
const max_input = 98
const max_output = 104

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'random_3sat_hajiaghayi_sorkin_algorithm_a']
pub fn random_3sat_hajiaghayi_sorkin_algorithm_a(input &i64, length usize, mut output &u8, capacity usize) i64 {
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
	for clause in 0 .. m {
		mut seen := [max_vars]bool{}
		for at in 0 .. 3 {
			raw := unsafe { input[2 + 3 * clause + at] }
			if raw == 0 || raw < -n64 || raw > n64 { return -1 }
			variable := int(if raw > 0 { raw } else { -raw }) - 1
			if seen[variable] { return -1 }
			seen[variable] = true
			clauses[clause][at] = int(raw)
		}
		lens[clause] = 3
		active[clause] = true
	}
	mut assigned := [max_vars]int{}
	mut assigned_count := 0
	mut failed := false
	for assigned_count < n {
		mut positive := [max_vars]int{}
		mut negative := [max_vars]int{}
		for clause in 0 .. m {
			if active[clause] {
				for at in 0 .. lens[clause] {
					literal := clauses[clause][at]
					variable := int(if literal > 0 { literal } else { -literal }) - 1
					if literal > 0 { positive[variable]++ } else { negative[variable]++ }
				}
			}
		}
		mut chosen_variable := -1
		for variable in 0 .. n {
			if assigned[variable] == 0 && (positive[variable] == 0 || negative[variable] == 0) {
				chosen_variable = variable
				break
			}
		}
		if chosen_variable < 0 {
			mut best_difference := -1
			mut best_total := -1
			for variable in 0 .. n {
				if assigned[variable] != 0 { continue }
				difference := int(if positive[variable] > negative[variable] { positive[variable] - negative[variable] } else { negative[variable] - positive[variable] })
				total := positive[variable] + negative[variable]
				if difference > best_difference || (difference == best_difference && total > best_total) {
					chosen_variable = variable
					best_difference = difference
					best_total = total
				}
			}
		}
		if chosen_variable < 0 { failed = true; break }
		mut chosen := -(chosen_variable + 1)
		if positive[chosen_variable] < negative[chosen_variable] { chosen = chosen_variable + 1 }
		assigned[chosen_variable] = if chosen > 0 { 1 } else { -1 }
		assigned_count++
		for clause in 0 .. m {
			if !active[clause] { continue }
			mut satisfied := false
			for at in 0 .. lens[clause] { if clauses[clause][at] == chosen { satisfied = true } }
			if satisfied { active[clause] = false; continue }
			mut write := 0
			for at in 0 .. lens[clause] {
				if clauses[clause][at] != -chosen { clauses[clause][write] = clauses[clause][at]; write++ }
			}
			lens[clause] = write
			if write == 0 { failed = true; break }
		}
		if failed { break }
		for {
			mut unit := 0
			for clause in 0 .. m { if unit == 0 && active[clause] && lens[clause] == 1 { unit = clauses[clause][0] } }
			if unit == 0 { break }
			variable := int(if unit > 0 { unit } else { -unit }) - 1
			assigned[variable] = if unit > 0 { 1 } else { -1 }
			assigned_count++
			for clause in 0 .. m {
				if !active[clause] { continue }
				mut satisfied := false
				for at in 0 .. lens[clause] { if clauses[clause][at] == unit { satisfied = true } }
				if satisfied { active[clause] = false; continue }
				mut write := 0
				for at in 0 .. lens[clause] {
					if clauses[clause][at] != -unit { clauses[clause][write] = clauses[clause][at]; write++ }
				}
				lens[clause] = write
				if write == 0 { failed = true; break }
			}
			if failed { break }
		}
		if failed { break }
	}
	bytes := 8 * (n + 1)
	if output == nil || capacity < usize(bytes) { return -2 }
	mut staged := [max_output]u8{}
	put_i64(mut &staged[0], 0, if failed { 0 } else { 1 })
	for variable in 0 .. n { put_i64(mut &staged[0], 8 * (variable + 1), i64(assigned[variable])) }
	for byte in 0 .. bytes { unsafe { output[byte] = staged[byte] } }
	return i64(bytes)
}
