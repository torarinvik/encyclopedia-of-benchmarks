module binary_prime_constant_sequence

const max_count = 4096

fn is_prime(candidate i64) bool {
	if candidate < 2 { return false }
	mut divisor := i64(2)
	for divisor <= candidate / divisor {
		if candidate % divisor == 0 { return false }
		divisor++
	}
	return true
}

@[export: 'binary_prime_constant_sequence']
pub fn binary_prime_constant_sequence(input &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_count { return -1 }
	count := int(count_value)
	if output_capacity < usize(count) { return -2 }

	mut next := 1
	mut candidate := i64(2)
	for candidate <= count_value {
		if is_prime(candidate) {
			for next < int(candidate) {
				unsafe { output[next - 1] = u8(0) }
				next++
			}
			unsafe { output[int(candidate) - 1] = u8(1) }
			next = int(candidate) + 1
		}
		candidate++
	}
	for next <= count {
		unsafe { output[next - 1] = u8(0) }
		next++
	}
	return i64(count)
}
