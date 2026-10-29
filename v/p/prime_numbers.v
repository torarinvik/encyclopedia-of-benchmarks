module prime_numbers

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	mut quotient := value / divisor
	for divisor <= quotient {
		if value - quotient * divisor == 0 { return false }
		divisor++
		quotient = value / divisor
	}
	return true
}

fn decimal_length(value i64) usize {
	mut remaining := value
	mut length := usize(1)
	for remaining >= 10 {
		remaining /= 10
		length++
	}
	return length
}

fn required_length(limit i64) usize {
	mut length := usize(0)
	mut count := usize(0)
	for value := i64(2); value <= limit; value++ {
		if is_prime(value) {
			length += decimal_length(value)
			if count > 0 { length++ }
			count++
		}
	}
	return length
}

fn append_decimal(value i64, output &u8, position_value usize) usize {
	mut digits := [3]u8{}
	mut count := 0
	mut remaining := value
	for remaining > 0 {
		digits[count] = u8(remaining % 10)
		count++
		remaining /= 10
	}
	mut position := position_value
	for count > 0 {
		count--
		unsafe { output[position] = u8(`0`) + digits[count] }
		position++
	}
	return position
}

// Encode all primes through an inclusive limit as comma-separated decimal bytes.
@[export: 'prime_numbers']
pub fn prime_numbers(limit i64, output &u8, output_capacity usize) i64 {
	if limit < 0 || limit > 80 { return -1 }
	required := required_length(limit)
	if output_capacity < required { return -2 }
	mut position := usize(0)
	mut count := usize(0)
	for value := i64(2); value <= limit; value++ {
		if is_prime(value) {
			if count > 0 {
				unsafe { output[position] = u8(`,`) }
				position++
			}
			position = append_decimal(value, output, position)
			count++
		}
	}
	return i64(position)
}
