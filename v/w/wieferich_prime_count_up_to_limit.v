module wieferich_prime_count_up_to_limit

const max_limit = 5000
const max_parseable_length = 2

fn modular_power(base_value i64, exponent_value i64, modulus i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn count_wieferich(limit int) i64 {
	mut prime := []u8{len: max_limit + 1}
	for n in 0 .. limit + 1 { prime[n] = 1 }
	prime[0] = 0
	prime[1] = 0
	mut divisor := 2
	for divisor * divisor <= limit {
		if prime[divisor] != 0 {
			mut multiple := divisor * divisor
			for multiple <= limit {
				prime[multiple] = 0
				multiple += divisor
			}
		}
		divisor++
	}
	mut count := i64(0)
	mut p := 3
	for p <= limit {
		if prime[p] != 0 {
			p64 := i64(p)
			if modular_power(2, p64 - 1, p64 * p64) == 1 { count++ }
		}
		p += 2
	}
	return count
}

@[export: 'wieferich_prime_count_up_to_limit']
pub fn wieferich_prime_count_up_to_limit(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 || input[0] < 2 || input[0] > max_limit { return -1 }
		return count_wieferich(int(input[0]))
	}
}
