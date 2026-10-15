module duval_algorithm

const max_length = usize(4096)

fn valid_input(values &i64, length usize) bool {
	if length > max_length { return false }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 127 { return false }
	}
	return true
}

fn factor_count(values &i64, length usize) usize {
	mut start := usize(0)
	mut count := usize(0)
	for start < length {
		mut end_index := start + 1
		mut repeat := start
		for end_index < length && unsafe { values[repeat] <= values[end_index] } {
			if unsafe { values[repeat] < values[end_index] } { repeat = start } else { repeat++ }
			end_index++
		}
		factor_length := end_index - repeat
		for start <= repeat {
			count++
			start += factor_length
		}
	}
	return count
}

fn store_u32_le(output &u8, offset usize, value usize) {
	packed := u32(value)
	for byte_index in 0 .. 4 {
		unsafe { output[offset + byte_index] = u8((packed >> (8 * byte_index)) & 255) }
	}
}

fn write_factors(values &i64, length usize, output &u8) {
	mut start := usize(0)
	mut factor_index := usize(0)
	for start < length {
		mut end_index := start + 1
		mut repeat := start
		for end_index < length && unsafe { values[repeat] <= values[end_index] } {
			if unsafe { values[repeat] < values[end_index] } { repeat = start } else { repeat++ }
			end_index++
		}
		factor_length := end_index - repeat
		for start <= repeat {
			store_u32_le(output, 4 * factor_index, factor_length)
			factor_index++
			start += factor_length
		}
	}
}

@[export: 'duval_algorithm']
pub fn duval_algorithm(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if !valid_input(values, length) { return -1 }
	count := factor_count(values, length)
	required := 4 * count
	if required == 0 { return 0 }
	if output_capacity < required { return -2 }
	write_factors(values, length, output)
	return i64(count)
}
