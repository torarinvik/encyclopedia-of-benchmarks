module totients_linear_sieve

fn decimal_length(value i64) usize {
	mut remaining := value
	mut length := usize(1)
	for remaining >= 10 { remaining /= 10; length++ }
	return length
}

fn append_decimal(value_input i64, output &u8, position_input usize) usize {
	mut digits := [3]u8{}
	mut count := usize(0)
	mut value := value_input
	for {
		digits[count] = u8(value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	mut position := position_input
	for count > 0 {
		count--
		unsafe { output[position] = u8(`0`) + digits[count] }
		position++
	}
	return position
}

@[export: 'totients_linear_sieve']
pub fn totients_linear_sieve(n i64, output &u8, output_capacity usize) i64 {
	if n < 1 || n > 80 { return -1 }
	mut phi := [81]i64{}
	mut composite := [81]i64{}
	mut primes := [80]i64{}
	mut prime_count := usize(0)
	phi[1] = 1
	for i in 2 .. n + 1 {
		if composite[i] == 0 {
			primes[prime_count] = i
			prime_count++
			phi[i] = i - 1
		}
		mut j := usize(0)
		for j < prime_count {
			p := primes[j]
			if i * p > n { break }
			composite[i * p] = 1
			if i % p == 0 {
				phi[i * p] = phi[i] * p
				break
			}
			phi[i * p] = phi[i] * (p - 1)
			j++
		}
	}
	mut required := usize(n - 1)
	for i in 1 .. n + 1 { required += decimal_length(phi[i]) }
	if output_capacity < required { return -2 }
	mut position := usize(0)
	for i in 1 .. n + 1 {
		if i > 1 {
			unsafe { output[position] = u8(`,`) }
			position++
		}
		position = append_decimal(phi[i], output, position)
	}
	return i64(position)
}
