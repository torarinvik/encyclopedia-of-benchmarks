module sum_over_subsets_zeta_transform

const max_values = 64
const max_input_length = 66
const max_function_value = i64(1000000)

fn transform(mut values [max_values]i64, bit_count int, state_count int) i64 {
	for bit_index in 0 .. bit_count {
		bit_mask := 1 << bit_index
		for mask in 0 .. state_count {
			if (mask & bit_mask) != 0 {
				values[mask] += values[mask ^ bit_mask]
			}
		}
	}
	mut checksum := i64(0)
	for mask in 0 .. state_count {
		checksum += i64(mask + 1) * values[mask]
	}
	return checksum
}

@[export: 'sum_over_subsets_zeta_transform']
pub fn sum_over_subsets_zeta_transform(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		bit_count64 := input[0]
		if bit_count64 < 0 || bit_count64 > 6 { return -1 }
		bit_count := int(bit_count64)
		state_count := 1 << bit_count
		if length != usize(state_count + 1) { return -1 }
		mut values := [max_values]i64{}
		for mask in 0 .. state_count {
			value := input[mask + 1]
			if value < 0 || value > max_function_value { return -1 }
			values[mask] = value
		}
		return transform(mut values, bit_count, state_count)
	}
}
