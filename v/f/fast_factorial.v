module fast_factorial

const max_n = 20
const max_buckets = 8

fn exponent_in_factorial(prime i64, n i64) i64 {
	mut exponent := i64(0)
	mut quotient := n / prime
	for quotient > 0 {
		exponent += quotient
		quotient /= prime
	}
	return exponent
}

fn power_by_squaring(base i64, exponent_value u32) i64 {
	mut result := i64(1)
	mut factor := base
	mut remaining := exponent_value
	for remaining > 0 {
		if (remaining & 1) != 0 { result *= factor }
		remaining >>= 1
		if remaining > 0 { factor *= factor }
	}
	return result
}

@[export: 'fast_factorial']
pub fn fast_factorial(n i64) i64 {
	if n < 0 || n > i64(max_n) { return -1 }
	if n < 2 { return 1 }

	mut is_prime := [max_n + 1]bool{init: false}
	for candidate in 2 .. int(n) + 1 { is_prime[candidate] = true }
	mut prime := 2
	for prime * prime <= int(n) {
		if is_prime[prime] {
			mut multiple := prime * prime
			for multiple <= int(n) {
				is_prime[multiple] = false
				multiple += prime
			}
		}
		prime++
	}

	exponent_of_two := exponent_in_factorial(2, n)
	mut next_power_of_two := i64(1)
	mut power_log2 := u32(0)
	for next_power_of_two < exponent_of_two {
		next_power_of_two *= 2
		power_log2++
	}
	bucket_count := int(power_log2 + 1)
	mut buckets := [max_buckets]i64{init: 1}

	for candidate in 2 .. int(n) + 1 {
		if !is_prime[candidate] { continue }
		exponent_bits := u32(exponent_in_factorial(i64(candidate), n))
		mut mask := u32(1)
		for bit in 0 .. bucket_count {
			if (exponent_bits & mask) != 0 { buckets[bit] *= i64(candidate) }
			mask <<= 1
		}
	}

	mut result := i64(1)
	mut power_exponent := u32(1)
	for bit in 0 .. bucket_count {
		result *= power_by_squaring(buckets[bit], power_exponent)
		power_exponent <<= 1
	}
	return result
}
