module get_primes_between

const max_prime_count = 256

fn is_prime_candidate(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn decimal_length(value i64) int {
	if value >= 100 { return 3 }
	if value >= 10 { return 2 }
	return 1
}

fn write_decimal(output &u8, mut offset int, value i64) {
	mut remaining := value
	if remaining >= 100 {
		unsafe { output[offset] = u8(48 + remaining / 100) }
		offset++
		remaining %= 100
	}
	if remaining >= 10 {
		unsafe { output[offset] = u8(48 + remaining / 10) }
		offset++
		remaining %= 10
	}
	unsafe { output[offset] = u8(48 + remaining) }
	offset++
}

@[export: 'get_primes_between']
pub fn get_primes_between(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length != 2 { return -1 }
		p1 := values[0]
		p2 := values[1]
		if p1 < 2 || p1 > 997 || p2 < 2 || p2 > 997 || p1 >= p2 { return -1 }
		if !is_prime_candidate(p1) || !is_prime_candidate(p2) { return -1 }

		mut primes := [max_prime_count]i64{init: 0}
		mut count := 0
		for candidate := p1 + 1; candidate < p2; candidate++ {
			if is_prime_candidate(candidate) {
				primes[count] = candidate
				count++
			}
		}
		if count == 0 { return -1 }

		mut required := count - 1
		for index := 0; index < count; index++ {
			required += decimal_length(primes[index])
		}
		if output == nil || output_capacity < usize(required) { return -2 }

		mut written := 0
		for index := 0; index < count; index++ {
			if index != 0 {
				output[written] = `,`
				written++
			}
			write_decimal(output, mut written, primes[index])
		}
		return i64(written)
	}
}
