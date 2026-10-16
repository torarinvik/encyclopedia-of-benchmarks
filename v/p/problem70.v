module problem70

const max_n = u32(10_000_000)
const prime_limit = 3162
const prime_capacity = 500
const segment_size = 32768

fn same_digits(left_value u32, right_value u32) bool {
	mut counts := [10]int{}
	mut left := left_value
	for left != 0 {
		counts[int(left % 10)]++
		left /= 10
	}
	mut right := right_value
	for right != 0 {
		counts[int(right % 10)]--
		right /= 10
	}
	for count in counts {
		if count != 0 { return false }
	}
	return true
}

@[export: 'problem70']
pub fn problem70(max_n_value i64) i64 {
	if max_n_value < 0 || max_n_value > i64(max_n) { return -1 }
	limit := u32(max_n_value)
	mut prime_flags := []bool{len: prime_limit + 1}
	mut primes := []u32{len: prime_capacity}
	mut prime_count := 0
	mut value := 2
	for value <= prime_limit && value <= int(limit) / value {
		prime_flags[value] = true
		value++
	}
	mut prime := 2
	for prime <= prime_limit && prime <= int(limit) / prime {
		if prime_flags[prime] {
			mut multiple := prime * prime
			for multiple <= prime_limit && multiple <= int(limit) / multiple {
				prime_flags[multiple] = false
				multiple += prime
			}
		}
		prime++
	}
	value = 2
	for value <= prime_limit && value <= int(limit) / value {
		if prime_flags[value] {
			primes[prime_count] = u32(value)
			prime_count++
		}
		value++
	}

	mut phi := []u32{len: segment_size}
	mut remainder := []u32{len: segment_size}
	mut best_n := u32(1)
	mut best_phi := u32(0)
	mut low := u32(0)
	for low <= limit {
		mut high := low + u32(segment_size) - 1
		if high < low || high > limit { high = limit }
		length := int(high - low + 1)
		for offset in 0 .. length {
			phi[offset] = low + u32(offset)
			remainder[offset] = low + u32(offset)
		}
		for index in 0 .. prime_count {
			factor := primes[index]
			mut first := low + (factor - low % factor) % factor
			if first < factor { first = factor }
			mut multiple := first
			for multiple <= high {
				offset := int(multiple - low)
				phi[offset] -= phi[offset] / factor
				for remainder[offset] % factor == 0 { remainder[offset] /= factor }
				if high - multiple < factor { break }
				multiple += factor
			}
		}
		for offset in 0 .. length {
			if remainder[offset] > 1 { phi[offset] -= phi[offset] / remainder[offset] }
			number := low + u32(offset)
			if number >= 2 && u64(number) * u64(best_phi) < u64(best_n) * u64(phi[offset]) && same_digits(number, phi[offset]) {
				best_n = number
				best_phi = phi[offset]
			}
		}
		if high == limit { break }
		low = high + 1
	}
	return i64(best_n)
}
