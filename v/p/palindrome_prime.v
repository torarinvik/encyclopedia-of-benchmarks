module palindrome_prime

fn is_prime(value u32) bool {
	if value < 2 { return false }
	mut divisor := u32(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn reverse_decimal(value u32) u32 {
	mut remaining := value
	mut reversed := u32(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed
}

fn write_u32_le(output &u8, position usize, value u32) {
	unsafe {
		output[position] = u8(value)
		output[position + 1] = u8(value >> 8)
		output[position + 2] = u8(value >> 16)
		output[position + 3] = u8(value >> 24)
	}
}

// Encode the first n palindrome primes as little-endian u32 values.
@[export: 'palindrome_prime']
pub fn palindrome_prime(n i64, output &u8, output_capacity usize) i64 {
	if n > 16 { return -1 }
	if n <= 0 { return 0 }
	required := usize(n) * 4
	if output_capacity < required { return -2 }
	write_u32_le(output, 0, 2)
	mut count := usize(1)
	mut candidate := u32(3)
	for count < usize(n) {
		if candidate == reverse_decimal(candidate) && is_prime(candidate) {
			write_u32_le(output, count * 4, candidate)
			count++
		}
		candidate += 2
	}
	return i64(required)
}
