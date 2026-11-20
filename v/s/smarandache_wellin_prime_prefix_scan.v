module smarandache_wellin_prime_prefix_scan

fn small_prime(value u64) bool {
	if value < 2 { return false }
	mut divisor := u64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn multiply_mod(left u64, right u64, modulus u64) u64 {
	return (left * right) % modulus
}

fn power_mod(initial_base u64, initial_exponent u64, modulus u64) u64 {
	mut base := initial_base % modulus
	mut exponent := initial_exponent
	mut result := u64(1)
	for exponent != 0 {
		if exponent & 1 != 0 { result = multiply_mod(result, base, modulus) }
		exponent >>= 1
		if exponent != 0 { base = multiply_mod(base, base, modulus) }
	}
	return result
}

fn prime_prefix(value u64) bool {
	small_primes := [12]u64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}
	bases := [3]u64{2, 7, 61}
	if value < 2 { return false }
	for prime in small_primes {
		if value == prime { return true }
		if value % prime == 0 { return false }
	}
	mut odd_part := value - 1
	mut twos := 0
	for odd_part & 1 == 0 {
		odd_part >>= 1
		twos++
	}
	for base in bases {
		mut witness := power_mod(base, odd_part, value)
		if witness == 1 || witness == value - 1 { continue }
		mut round := 1
		for round < twos && witness != value - 1 {
			witness = multiply_mod(witness, witness, value)
			round++
		}
		if witness != value - 1 { return false }
	}
	return true
}

@[export: 'smarandache_wellin_prime_prefix_scan']
pub fn smarandache_wellin_prime_prefix_scan(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 2 { return -1 }
	count := unsafe { input[0] }
	if count < 0 || count > 6 || length != 1 { return -1 }

	mut values := [3]u64{}
	mut result_count := 0
	mut prefix := u64(0)
	mut candidate := u64(2)
	for _ in 0 .. count {
		for !small_prime(candidate) {
			if candidate == 2 { candidate++ } else { candidate += 2 }
		}
		mut scale := u64(10)
		for scale <= candidate { scale *= 10 }
		prefix = prefix * scale + candidate
		if prime_prefix(prefix) {
			values[result_count] = prefix
			result_count++
		}
		if candidate == 2 { candidate++ } else { candidate += 2 }
	}

	byte_count := result_count * 8
	if unsafe { output == nil } || capacity < byte_count { return -2 }
	mut staged := [24]u8{}
	for item in 0 .. result_count {
		for byte in 0 .. 8 { staged[item * 8 + byte] = u8((values[item] >> u64(byte * 8)) & 255) }
	}
	for byte in 0 .. byte_count { unsafe { output[byte] = staged[byte] } }
	return i64(byte_count)
}
