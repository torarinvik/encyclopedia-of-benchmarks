module addition_chain_enumeration

const max_target = 31
const output_bytes = usize(24)

struct Search {
	target int
	limit int
	chain [32]int
	total_count i64
	brauer_count i64
}

fn visit(mut state &Search, length int, prefix_is_brauer bool) {
	last := state.chain[length - 1]
	steps := length - 1
	if last == state.target {
		if steps == state.limit {
			state.total_count++
			if prefix_is_brauer { state.brauer_count++ }
		}
		return
	}
	remaining := state.limit - steps
	if remaining <= 0 || last * (1 << remaining) < state.target { return }

	mut generated := [32]bool{}
	for left in 0 .. length {
		for right in left .. length {
			candidate := state.chain[left] + state.chain[right]
			if candidate <= last || candidate > state.target || generated[candidate] { continue }
			generated[candidate] = true
			state.chain[length] = candidate
			mut uses_last := false
			for index in 0 .. length {
				if last + state.chain[index] == candidate { uses_last = true }
			}
			visit(mut state, length + 1, prefix_is_brauer && uses_last)
		}
	}
}

fn bit_length(value_input int) int {
	mut value := value_input
	mut count := 0
	for value != 0 {
		count++
		value >>= 1
	}
	return count
}

fn popcount(value_input int) int {
	mut value := value_input
	mut count := 0
	for value != 0 {
		count += value & 1
		value >>= 1
	}
	return count
}

fn minimum_counts(target int) [3]i64 {
	if target == 1 { return [3]i64{0, 1, 0} }
	lower := bit_length(target - 1)
	upper := bit_length(target) - 1 + popcount(target) - 1
	for limit in lower .. upper + 1 {
		mut state := Search{target: target, limit: limit}
		state.chain[0] = 1
		visit(mut state, 1, true)
		if state.total_count != 0 {
			return [3]i64{i64(limit), state.brauer_count, state.total_count - state.brauer_count}
		}
	}
	return [3]i64{}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits >> (byte * 8)) } }
}

@[export: 'addition_chain_enumeration']
pub fn addition_chain_enumeration(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		target_value := input[0]
		if target_value < 1 || target_value > max_target { return -1 }
		result := minimum_counts(int(target_value))
		if output == nil || output_capacity < output_bytes { return -2 }
		for index in 0 .. 3 { store_i64_le(mut output, index * 8, result[index]) }
		return i64(output_bytes)
	}
}
