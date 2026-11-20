module goodstein_sequence_bounded_prefix

const max_input_words = 3
const max_transitions = i64(16)

fn small_power(base i64, exponent i64) i64 {
	mut result := i64(1)
	for _ in 0 .. int(exponent) {
		result *= base
	}
	return result
}

fn rebase_hereditary(value i64, base i64, raised_base i64) i64 {
	if value == 0 { return 0 }
	mut result := i64(0)
	mut place := i64(1)
	mut exponent := i64(0)
	for place <= value {
		digit := (value / place) % base
		if digit != 0 {
			raised_exponent := rebase_hereditary(exponent, base, raised_base)
			result += digit * small_power(raised_base, raised_exponent)
		}
		place *= base
		exponent++
	}
	return result
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'goodstein_sequence_bounded_prefix']
pub fn goodstein_sequence_bounded_prefix(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_input_words) || length != 2 { return -1 }
	start := unsafe { input[0] }
	transitions := unsafe { input[1] }
	if start < 0 || start > 4 || transitions < 0 || transitions > max_transitions { return -1 }

	mut terms := [17]i64{}
	mut count := 1
	terms[0] = start
	mut current := start
	mut base := i64(2)
	for _ in 0 .. int(transitions) {
		if current == 0 { break }
		current = rebase_hereditary(current, base, base + 1) - 1
		base++
		terms[count] = current
		count++
	}

	output_bytes := (count + 1) * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	unsafe {
		store_i64_le(output, 0, i64(count))
		for index in 0 .. count {
			store_i64_le(output, (index + 1) * 8, terms[index])
		}
	}
	return i64(output_bytes)
}
