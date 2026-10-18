package get_primes_between

import "core:c"

MAX_PRIME_COUNT :: 256

is_prime_candidate :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

decimal_length :: proc "contextless" (value: i64) -> int {
	if value >= 100 do return 3
	if value >= 10 do return 2
	return 1
}

write_decimal :: proc "contextless" (output: [^]u8, offset: ^int, value: i64) {
	remaining := value
	if remaining >= 100 {
		output[offset^] = u8(48 + remaining / 100)
		offset^ += 1
		remaining %= 100
	}
	if remaining >= 10 {
		output[offset^] = u8(48 + remaining / 10)
		offset^ += 1
		remaining %= 10
	}
	output[offset^] = u8(48 + remaining)
	offset^ += 1
}

@(export)
get_primes_between :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	p1 := values[0]
	p2 := values[1]
	if p1 < 2 || p1 > 997 || p2 < 2 || p2 > 997 || p1 >= p2 do return -1
	if !is_prime_candidate(p1) || !is_prime_candidate(p2) do return -1

	primes: [MAX_PRIME_COUNT]i64
	count := 0
	for candidate := p1 + 1; candidate < p2; candidate += 1 {
		if is_prime_candidate(candidate) {
			primes[count] = candidate
			count += 1
		}
	}
	if count == 0 do return -1

	required := count - 1
	for index := 0; index < count; index += 1 {
		required += decimal_length(primes[index])
	}
	if output == nil || output_capacity < c.size_t(required) do return -2

	written := 0
	for index := 0; index < count; index += 1 {
		if index != 0 {
			output[written] = u8(',')
			written += 1
		}
		write_decimal(output, &written, primes[index])
	}
	return i64(written)
}
