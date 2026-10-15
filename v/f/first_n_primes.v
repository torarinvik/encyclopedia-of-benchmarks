module first_n_primes

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
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

fn required_length(number_of_primes i64) usize {
	mut length := usize(0)
	mut count := i64(0)
	mut value := i64(2)
	for count < number_of_primes {
		if is_prime(value) {
			length += decimal_length(value)
			if count > 0 { length++ }
			count++
		}
		value++
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

// Encode the first n primes in ascending order as comma-separated decimal bytes.
@[export: 'first_n_primes']
pub fn first_n_primes(number_of_primes i64, output &u8, output_capacity usize) i64 {
	if number_of_primes < 0 || number_of_primes > 20 { return -1 }
	required := required_length(number_of_primes)
	if output_capacity < required { return -2 }
	mut position := usize(0)
	mut count := i64(0)
	mut value := i64(2)
	for count < number_of_primes {
		if is_prime(value) {
			if count > 0 {
				unsafe { output[position] = u8(`,`) }
				position++
			}
			position = append_decimal(value, output, position)
			count++
		}
		value++
	}
	return i64(position)
}
