module quine_mccluskey_minimization

const (
	max_variables = 3
	max_cubes = 27
	max_states = 256
	max_input_length = 9
	inf_cost = 99
)

fn cube_valid(care u32, value u32, input &i64, size int) bool {
	mut cover := u32(0)
	for minterm in 0 .. size {
		if (u32(minterm) & care) == value {
			status := unsafe { input[1 + minterm] }
			if status == 0 { return false }
			if status == 1 { cover |= u32(1) << minterm }
		}
	}
	return cover != 0
}

fn lex_better(candidate u32, incumbent u32, count int) bool {
	for index in 0 .. count {
		bit := u32(1) << index
		left := (candidate & bit) != 0
		right := (incumbent & bit) != 0
		if left != right { return left }
	}
	return false
}

@[export: 'quine_mccluskey_minimization']
pub fn quine_mccluskey_minimization(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	n_arg := unsafe { input[0] }
	if n_arg < 1 || n_arg > i64(max_variables) { return -1 }
	n := int(n_arg)
	size := 1 << n
	if length != 1 + size { return -1 }
	for minterm in 0 .. size {
		status := unsafe { input[1 + minterm] }
		if status < 0 || status > 2 { return -1 }
	}

	mut cares := [27]u32{}
	mut values := [27]u32{}
	mut covers := [27]u32{}
	mut literal_counts := [27]int{}
	mut prime_count := 0
	full := u32(size - 1)
	for care in u32(0) .. full + 1 {
		for value in u32(0) .. full + 1 {
			if (value & ~care) != 0 || !cube_valid(care, value, input, size) { continue }
			mut prime := true
			for variable in 0 .. n {
				bit := u32(1) << variable
				if (care & bit) != 0 && cube_valid(care ^ bit, value & ~bit, input, size) {
					prime = false
					break
				}
			}
			if !prime { continue }
			mut cover := u32(0)
			mut literal_count := 0
			for minterm in 0 .. size {
				status := unsafe { input[1 + minterm] }
				if (u32(minterm) & care) == value && status == 1 {
					cover |= u32(1) << minterm
				}
			}
			for variable in 0 .. n {
				if (care & (u32(1) << variable)) != 0 { literal_count++ }
			}
			cares[prime_count] = care
			values[prime_count] = value
			covers[prime_count] = cover
			literal_counts[prime_count] = literal_count
			prime_count++
		}
	}
	mut on_mask := u32(0)
	for minterm in 0 .. size {
		if unsafe { input[1 + minterm] } == 1 { on_mask |= u32(1) << minterm }
	}
	state_count := 1 << size
	mut term_cost := [256]int{}
	mut literal_cost := [256]int{}
	mut selected := [256]u32{}
	for state in 0 .. state_count {
		term_cost[state] = inf_cost
		literal_cost[state] = inf_cost
	}
	term_cost[0] = 0
	literal_cost[0] = 0
	for index in 0 .. prime_count {
		prime_bit := u32(1) << index
		mut state := state_count
		for state > 0 {
			state--
			if term_cost[state] == inf_cost { continue }
			destination := state | int(covers[index])
			if destination == state { continue }
			new_terms := term_cost[state] + 1
			new_literals := literal_cost[state] + literal_counts[index]
			new_selected := selected[state] | prime_bit
			mut better := new_terms < term_cost[destination]
			if new_terms == term_cost[destination] {
				better = new_literals < literal_cost[destination]
				if new_literals == literal_cost[destination] {
					better = lex_better(new_selected, selected[destination], prime_count)
				}
			}
			if better {
				term_cost[destination] = new_terms
				literal_cost[destination] = new_literals
				selected[destination] = new_selected
			}
		}
	}
	chosen := selected[int(on_mask)]
	mut term_count := 0
	for index in 0 .. prime_count {
		if (chosen & (u32(1) << index)) != 0 { term_count++ }
	}
	output_bytes := 8 * (1 + 2 * term_count)
	if output == nil || capacity < usize(output_bytes) { return -2 }
	mut words := [17]i64{}
	words[0] = i64(term_count)
	mut cursor := 1
	for index in 0 .. prime_count {
		if (chosen & (u32(1) << index)) != 0 {
			words[cursor] = i64(cares[index])
			cursor++
			words[cursor] = i64(values[index])
			cursor++
		}
	}
	for word in 0 .. cursor {
		mut bits := u64(words[word])
		for byte in 0 .. 8 {
			unsafe { output[word * 8 + byte] = u8(bits & 255) }
			bits >>= 8
		}
	}
	return i64(output_bytes)
}
