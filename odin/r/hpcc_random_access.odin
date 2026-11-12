package hpcc_random_access

import "core:c"

MAX_TABLE_SIZE :: 256
DIGEST_MASK :: u64(0x7fff_ffff_ffff_ffff)

@(export)
hpcc_random_access :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	size_value := input[0]
	if size_value < 2 || size_value > MAX_TABLE_SIZE do return -1
	if (size_value & (size_value - 1)) != 0 do return -1

	size := int(size_value)
	table: [MAX_TABLE_SIZE]u64
	for index in 0..<size do table[index] = u64(index)

	ran := u64(1)
	for _ in 0..<(4 * size) {
		feedback := u64(0)
		if (ran >> 63) != 0 do feedback = 7
		// Drop the outgoing high bit before shifting to express u64 wrap.
		ran = ((ran & digest_mask) << 1) ^ feedback
		table[int(ran & u64(size - 1))] ^= ran
	}

	// Odin u64 arithmetic wraps modulo 2^64, matching the digest contract.
	digest := u64(0)
	for index in 0..<size {
		digest += u64(index + 1) * table[index]
	}
	return i64(digest & DIGEST_MASK)
}
