module numbers_with_prime_divisor_count_not_two

const max_input_length = 2
const max_limit = 1000

fn is_prime_count(value u16) bool {
	if value < 2 { return false }
	mut divisor := u16(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn store_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'numbers_with_prime_divisor_count_not_two']
pub fn numbers_with_prime_divisor_count_not_two(input &i64, length usize,
	output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 1 || input[0] > max_limit { return -1 }
		mut divisor_counts := [max_limit]u16{init: 0}
		limit := int(input[0])
		for divisor := 1; divisor < limit; divisor++ {
			mut multiple := divisor
			for multiple < limit {
				divisor_counts[multiple]++
				multiple += divisor
			}
		}
		mut selected_count := 0
		for n := 1; n < limit; n++ {
			count := divisor_counts[n]
			if count != 2 && is_prime_count(count) { selected_count++ }
		}
		output_bytes := selected_count * 8
		if output == nil || capacity < output_bytes { return -2 }
		mut output_index := 0
		for n := 1; n < limit; n++ {
			count := divisor_counts[n]
			if count != 2 && is_prime_count(count) {
				store_i64(mut output, output_index * 8, i64(n))
				output_index++
			}
		}
		return i64(output_bytes)
	}
}
