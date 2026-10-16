package problem70

const MAX_N = 10_000_000
const PRIME_LIMIT = 3162
const PRIME_CAPACITY = 500
const SEGMENT_SIZE = 32768

same_digits :: proc(left_value, right_value: u32) -> bool {
	counts: [10]int
	for digit := 0; digit < 10; digit += 1 { counts[digit] = 0 }
	left := left_value
	for left != 0 { counts[left % 10] += 1; left /= 10 }
	right := right_value
	for right != 0 { counts[right % 10] -= 1; right /= 10 }
	for count in counts { if count != 0 do return false }
	return true
}

@(export)
problem70 :: proc "c" (max_n: i64) -> i64 {
	if max_n < 0 || max_n > MAX_N do return -1
	limit := u32(max_n)
	prime_flags: [PRIME_LIMIT + 1]bool
	primes: [PRIME_CAPACITY]u32
	for index := 0; index <= PRIME_LIMIT; index += 1 { prime_flags[index] = false }
	prime_count := 0
	for value := 2; value <= PRIME_LIMIT && value <= int(limit) / value; value += 1 { prime_flags[value] = true }
	for prime := 2; prime <= PRIME_LIMIT && prime <= int(limit) / prime; prime += 1 {
		if !prime_flags[prime] do continue
		for multiple := prime * prime; multiple <= PRIME_LIMIT && multiple <= int(limit) / multiple; multiple += prime {
			prime_flags[multiple] = false
		}
	}
	for value := 2; value <= PRIME_LIMIT && value <= int(limit) / value; value += 1 {
		if prime_flags[value] { primes[prime_count] = u32(value); prime_count += 1 }
	}

	phi: [SEGMENT_SIZE]u32
	remainder: [SEGMENT_SIZE]u32
	best_n := u32(1)
	best_phi := u32(0)
	low := u32(0)
	for low <= limit {
		high := low + u32(SEGMENT_SIZE) - 1
		if high < low || high > limit { high = limit }
		length := int(high - low + 1)
		for offset := 0; offset < length; offset += 1 {
			phi[offset] = low + u32(offset)
			remainder[offset] = low + u32(offset)
		}
		for index := 0; index < prime_count; index += 1 {
			factor := primes[index]
			first := low + (factor - low % factor) % factor
			if first < factor { first = factor }
			for multiple := first; multiple <= high; {
				offset := int(multiple - low)
				phi[offset] -= phi[offset] / factor
				for remainder[offset] % factor == 0 { remainder[offset] /= factor }
				if high - multiple < factor do break
				multiple += factor
			}
		}
		for offset := 0; offset < length; offset += 1 {
			if remainder[offset] > 1 { phi[offset] -= phi[offset] / remainder[offset] }
			number := low + u32(offset)
			if number >= 2 && u64(number) * u64(best_phi) < u64(best_n) * u64(phi[offset]) && same_digits(number, phi[offset]) {
				best_n = number
				best_phi = phi[offset]
			}
		}
		if high == limit do break
		low = high + 1
	}
	return i64(best_n)
}
