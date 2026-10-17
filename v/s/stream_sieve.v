module stream_sieve

const max_primes = 100

// V requires the build command to enable globals for this process-wide LazyList cache.
__global (
	mut prime_cache = [100]i32{}
	mut prime_count = 0
	mut next_candidate = i32(3)
)

fn is_prime_candidate(candidate i32) bool {
	for index in 0 .. prime_count {
		divisor := prime_cache[index]
		if divisor > candidate / divisor {
			break
		}
		if candidate % divisor == 0 {
			return false
		}
	}
	return true
}

fn extend_prime_cache(requested_count int) {
	if prime_count == 0 {
		prime_cache[0] = 2
		prime_count = 1
	}
	for prime_count < requested_count {
		candidate := next_candidate
		next_candidate++
		if is_prime_candidate(candidate) {
			prime_cache[prime_count] = candidate
			prime_count++
		}
	}
}

@[export: 'stream_sieve']
pub fn stream_sieve(number_of_primes i64, mut output &u8, output_capacity usize) i64 {
	if number_of_primes < -2147483648 || number_of_primes > i64(max_primes) {
		return -1
	}
	if number_of_primes <= 0 {
		return 0
	}
	count := int(number_of_primes)
	required := count * 4
	if output == nil || output_capacity < required {
		return -2
	}

	extend_prime_cache(count)
	for index in 0 .. count {
		mut bits := u32(prime_cache[index])
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8(bits & 255) }
			bits >>= 8
		}
	}
	return i64(required)
}
