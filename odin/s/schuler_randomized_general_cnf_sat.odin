package schuler_randomized_general_cnf_sat

import "core:c"

MAX_N :: 6
MAX_M :: 4
MAX_CALLS :: MAX_N + 1
MAX_INPUT :: 122

Formula :: [MAX_M][MAX_N]i64
Lengths :: [MAX_M]int
Values :: [MAX_N]int

Stats :: struct { calls, units, guesses, max_depth: i64 }

prefix_size :: proc "contextless" (m: int) -> int {
	remaining, bits := m, 0
	for remaining > 0 { bits += 1; remaining >>= 1 }
	return bits + 1
}

lit_true :: proc "contextless" (literal: i64, value: int) -> bool {
	if literal > 0 do return value == 1
	return value == 0
}

ppz :: proc "contextless" (n, m: int, formula: Formula, lengths: Lengths,
	fixed: Values, permutation, bits: [MAX_N]int, local: [^]int, stats: ^Stats) -> bool {
	var active: [MAX_N]int
	active_count := 0
	for variable := 0; variable < MAX_N; variable += 1 { local[variable] = -1 }
	for position := 0; position < n; position += 1 {
		variable := permutation[position] - 1
		if fixed[variable] < 0 {
			active[active_count] = variable
			active_count += 1
		}
	}
	work := formula
	work_lengths := lengths
	work_m := m
	for offset := 0; offset < active_count; offset += 1 {
		variable := active[offset]
		positive_unit, negative_unit := false, false
		for clause := 0; clause < work_m; clause += 1 {
			if work_lengths[clause] == 1 {
				positive_unit = positive_unit || work[clause][0] == i64(variable + 1)
				negative_unit = negative_unit || work[clause][0] == -i64(variable + 1)
			}
		}
		value := 0
		if positive_unit { value = 1; stats.units += 1 }
		else if negative_unit { value = 0; stats.units += 1 }
		else { value = bits[offset]; stats.guesses += 1 }
		local[variable] = value
		var next: Formula
		var next_lengths: Lengths
		next_m := 0
		for clause := 0; clause < work_m; clause += 1 {
			satisfied := false
			out_length := 0
			for item := 0; item < work_lengths[clause]; item += 1 {
				literal := work[clause][item]
				if int(abs(literal))-1 != variable {
					next[next_m][out_length] = literal
					out_length += 1
				} else if lit_true(literal, value) { satisfied = true; break }
			}
			if !satisfied { next_lengths[next_m] = out_length; next_m += 1 }
		}
		work, work_lengths, work_m = next, next_lengths, next_m
	}
	for clause := 0; clause < work_m; clause += 1 { if work_lengths[clause] == 0 do return false }
	return true
}

restrict_formula :: proc "contextless" (formula: Formula, lengths: Lengths, m: int,
	assignment: Values) -> (Formula, Lengths, int) {
	var next: Formula
	var next_lengths: Lengths
	next_m := 0
	for clause := 0; clause < m; clause += 1 {
		satisfied := false
		out_length := 0
		for item := 0; item < lengths[clause]; item += 1 {
			literal := formula[clause][item]
			value := assignment[int(abs(literal))-1]
			if value < 0 { next[next_m][out_length] = literal; out_length += 1 }
			else if lit_true(literal, value) { satisfied = true; break }
		}
		if !satisfied { next_lengths[next_m] = out_length; next_m += 1 }
	}
	return next, next_lengths, next_m
}

put_i64_le :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[8*word+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
schuler_randomized_general_cnf_sat :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M do return -1
	n, original_m := int(n0), int(m0)
	var formula: Formula
	var lengths: Lengths
	position := 2
	for clause := 0; clause < original_m; clause += 1 {
		if c.size_t(position) >= length do return -1
		count0 := input[position]
		position += 1
		if count0 < 1 || count0 > n0 || c.size_t(position) + c.size_t(count0) > length do return -1
		count := int(count0)
		var seen: [MAX_N]bool
		lengths[clause] = count
		for item := 0; item < count; item += 1 {
			literal := input[position]
			position += 1
			if literal == 0 || literal < -n0 || literal > n0 do return -1
			variable := int(abs(literal)) - 1
			if seen[variable] do return -1
			seen[variable] = true
			formula[clause][item] = literal
		}
	}
	var permutations: [MAX_CALLS][MAX_N]int
	var random_bits: [MAX_CALLS][MAX_N]int
	var choices: [MAX_CALLS]int
	for call := 0; call <= n; call += 1 {
		var seen: [MAX_N]bool
		for item := 0; item < n; item += 1 {
			if c.size_t(position) >= length do return -1
			value := input[position]
			position += 1
			if value < 1 || value > n0 || seen[int(value)-1] do return -1
			seen[int(value)-1] = true
			permutations[call][item] = int(value)
		}
		for item := 0; item < n; item += 1 {
			if c.size_t(position) >= length || (input[position] != 0 && input[position] != 1) do return -1
			random_bits[call][item] = int(input[position])
			position += 1
		}
		if c.size_t(position) >= length do return -1
		choice := input[position]
		position += 1
		if choice < 0 || choice >= m0 do return -1
		choices[call] = int(choice)
	}
	if c.size_t(position) != length do return -1
	var fixed: Values
	for variable := 0; variable < MAX_N; variable += 1 { fixed[variable] = -1 }
	current, current_lengths, current_m := formula, lengths, original_m
	stats := Stats{}
	found, mask, depth := false, i64(0), 0
	for {
		stats.calls += 1
		if i64(depth) > stats.max_depth { stats.max_depth = i64(depth) }
		if current_m == 0 {
			found = true
			for variable := 0; variable < n; variable += 1 { if fixed[variable] == 1 { mask |= i64(1) << variable } }
			break
		}
		k := prefix_size(current_m)
		var shortened: Formula
		var short_lengths: Lengths
		for clause := 0; clause < current_m; clause += 1 {
			short_lengths[clause] = min(current_lengths[clause], k)
			for item := 0; item < short_lengths[clause]; item += 1 { shortened[clause][item] = current[clause][item] }
		}
		var local: [MAX_N]int
		if ppz(n, current_m, shortened, short_lengths, fixed, permutations[depth], random_bits[depth], &local[0], &stats) {
			found = true
			for variable := 0; variable < n; variable += 1 {
				if fixed[variable] == 1 || (fixed[variable] < 0 && local[variable] == 1) { mask |= i64(1) << variable }
			}
			break
		}
		var eligible: [MAX_M]int
		eligible_count := 0
		for clause := 0; clause < current_m; clause += 1 {
			if short_lengths[clause] == k { eligible[eligible_count] = clause; eligible_count += 1 }
		}
		if eligible_count == 0 { break }
		if choices[depth] >= eligible_count do return -1
		selected := eligible[choices[depth]]
		next_fixed := fixed
		for item := 0; item < k; item += 1 {
			literal := shortened[selected][item]
			next_fixed[int(abs(literal))-1] = 0
			if literal < 0 { next_fixed[int(abs(literal))-1] = 1 }
		}
		next, next_lengths, next_m := restrict_formula(current, current_lengths, current_m, next_fixed)
		current, current_lengths, current_m = next, next_lengths, next_m
		fixed = next_fixed
		depth += 1
		if depth > n do return -1
	}
	if !found { mask = 0 }
	var staged: [6]i64 = {i64(found), mask, stats.calls, stats.units, stats.guesses, stats.max_depth}
	if output == nil || capacity < 48 do return -2
	for word := 0; word < 6; word += 1 { put_i64_le(output, word, staged[word]) }
	return 48
}
