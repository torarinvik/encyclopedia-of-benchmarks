package nsieve_bits

import "core:c"

MAX_LIMIT :: i64(1_000_000)
MAX_WORDS :: 15626

count_primes :: proc(limit: i64) -> i64 {
	bits: [MAX_WORDS]u64
	for word := 0; word < MAX_WORDS; word += 1 { bits[word] = 0xFFFFFFFFFFFFFFFF }
	count := i64(0)
	for value := i64(2); value <= limit; value += 1 {
		word := int(value / 64)
		mask := u64(1) << u64(value % 64)
		if bits[word] & mask != 0 {
			count += 1
			for multiple := value + value; multiple <= limit; multiple += value {
				multiple_word := int(multiple / 64)
				multiple_mask := u64(1) << u64(multiple % 64)
				if bits[multiple_word] & multiple_mask != 0 { bits[multiple_word] ^= multiple_mask }
			}
		}
	}
	return count
}

put_u64_le :: proc(output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(value >> u64(byte * 8)) }
}

@(export)
benchmarkgame_nsieve_bits :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 0 || input[0] > MAX_LIMIT do return -1
	if output == nil || capacity < 24 do return -2
	for pass := 0; pass < 3; pass += 1 { put_u64_le(output, pass * 8, u64(count_primes(input[0] >> pass))) }
	return 24
}
