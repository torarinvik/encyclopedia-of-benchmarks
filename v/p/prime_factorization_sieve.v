module prime_factorization_sieve

fn write_u32le(value u32, mut output &u8, position int) {
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
@[export: 'prime_factorization_sieve']
pub fn prime_factorization_sieve(value i64, mut output &u8, output_capacity usize) i64 {
	if value < 1 || value > 1_000_005 { return -1 }
	if value == 1 { return 0 }
	limit := int(value)
	mut is_prime := []bool{len: limit + 1, init: true}
	is_prime[0] = false
	is_prime[1] = false
	for prime := 2; prime <= limit / prime; prime++ {
		if !is_prime[prime] { continue }
		mut multiple := prime * prime
		for multiple <= limit {
			is_prime[multiple] = false
			multiple += prime
		}
	}

	mut primes := []u32{len: 10}
	mut exponents := []u32{len: 10}
	mut count := 0
	mut remaining := value
	for prime in 2 .. limit + 1 {
		if remaining == 1 { break }
		if !is_prime[prime] { continue }
		mut exponent := u32(0)
		for remaining % i64(prime) == 0 {
			remaining /= i64(prime)
			exponent++
		}
		if exponent != 0 {
			primes[count] = u32(prime)
			exponents[count] = exponent
			count++
		}
	}
	required := count * 8
	if output == nil || output_capacity < usize(required) { return -2 }
	for index in 0 .. count {
		write_u32le(primes[index], mut output, 8 * index)
		write_u32le(exponents[index], mut output, 8 * index + 4)
	}
	return i64(required)
}
