package segmented_sieve

import "core:c"

put_i64_le :: proc(value: i64, output: [^]u8, offset: usize) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
segmented_sieve :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 2 || input[0] > 10000 do return -1
	n := usize(input[0])
	end: usize = 0
	for (end + 1) * (end + 1) <= n { end += 1 }
	base_marks: [101]bool
	base: [25]i64
	base_count: usize = 0
	for i: usize = 2; i <= end; i += 1 { base_marks[i] = true }
	for p: usize = 2; p <= end; p += 1 {
		if !base_marks[p] do continue
		base[base_count] = i64(p)
		base_count += 1
		for multiple := p * p; multiple <= end; multiple += p { base_marks[multiple] = false }
	}
	primes: [1229]i64
	prime_count: usize = 0
	for i: usize = 0; i < base_count; i += 1 { primes[prime_count] = base[i]; prime_count += 1 }
	low := end + 1
	high := min(2 * end, n)
	for low <= n {
		segment: [201]bool
		segment_length := high - low + 1
		for i: usize = 0; i < segment_length; i += 1 { segment[i] = true }
		for i: usize = 0; i < base_count; i += 1 {
			p := usize(base[i])
			first := (low / p) * p
			if first < low { first += p }
			for first <= high { segment[first - low] = false; first += p }
		}
		for i: usize = 0; i < segment_length; i += 1 {
			if segment[i] { primes[prime_count] = i64(low + i); prime_count += 1 }
		}
		low = high + 1
		high = min(high + end, n)
	}
	output_length := prime_count * 8
	if capacity < output_length || (output_length > 0 && output == nil) do return -2
	for i: usize = 0; i < prime_count; i += 1 { put_i64_le(primes[i], output, i * 8) }
	return i64(output_length)
}
