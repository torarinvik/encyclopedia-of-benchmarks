module count_nucleotide

const max_sequence_length = 1000

fn decimal_length(value i64) usize {
	mut current := value
	mut length := usize(1)
	for current >= 10 {
		current /= 10
		length++
	}
	return length
}

fn write_decimal(output &u8, offset usize, value i64) usize {
	mut current := value
	mut divisor := i64(1)
	for current / divisor >= 10 { divisor *= 10 }
	mut position := offset
	for divisor > 0 {
		unsafe { output[position] = u8(48 + current / divisor) }
		position++
		current %= divisor
		divisor /= 10
	}
	return position
}

@[export: 'count_nucleotide']
pub fn count_nucleotide(values &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 1001 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_sequence_length || length != usize(count_value) + 1 { return -1 }
	mut count_a := i64(0)
	mut count_c := i64(0)
	mut count_g := i64(0)
	mut count_t := i64(0)
	for i in 0 .. usize(count_value) {
		codepoint := unsafe { values[1 + i] }
		if codepoint < 0 || codepoint > 127 { return -1 }
		if codepoint == 65 { count_a++ }
		else if codepoint == 67 { count_c++ }
		else if codepoint == 71 { count_g++ }
		else if codepoint == 84 { count_t++ }
	}
	output_length := decimal_length(count_a) + decimal_length(count_c) + decimal_length(count_g) + decimal_length(count_t) + 3
	if unsafe { output == nil } || capacity < output_length { return -2 }
	mut offset := write_decimal(output, 0, count_a)
	unsafe { output[offset] = 32 }; offset++
	offset = write_decimal(output, offset, count_c)
	unsafe { output[offset] = 32 }; offset++
	offset = write_decimal(output, offset, count_g)
	unsafe { output[offset] = 32 }; offset++
	offset = write_decimal(output, offset, count_t)
	return i64(offset)
}
