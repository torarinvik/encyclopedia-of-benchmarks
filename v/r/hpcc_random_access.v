module hpcc_random_access

const max_table_size = 256
const digest_mask = u64(0x7fff_ffff_ffff_ffff)

@[export: 'hpcc_random_access']
pub fn hpcc_random_access(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 {
		return -1
	}
	size_value := unsafe { input[0] }
	if size_value < 2 || size_value > max_table_size {
		return -1
	}
	if size_value & (size_value - 1) != 0 {
		return -1
	}

	size := int(size_value)
	mut table := [256]u64{}
	for index in 0 .. size {
		table[index] = u64(index)
	}

	mut ran := u64(1)
	for _ in 0 .. 4 * size {
		feedback := if ran >> 63 != 0 { u64(7) } else { u64(0) }
		// Clear the outgoing bit before shifting to express modulo-2^64 state.
		ran = ((ran & digest_mask) << 1) ^ feedback
		table[int(ran & u64(size - 1))] ^= ran
	}

	mut digest := u64(0)
	for index in 0 .. size {
		digest = digest +% (u64(index + 1) *% table[index])
	}
	return i64(digest & digest_mask)
}
