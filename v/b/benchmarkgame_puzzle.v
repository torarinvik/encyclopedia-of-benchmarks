module benchmarkgame_puzzle

const max_array_size = 100_000
const max_rounds = 8
const max_scans_per_array = 64

fn puzzle_rand(mut state u64) u32 {
	mask := u64(0xffff_ffff)
	low_product := (state & mask) * u64(1_103_515_245)
	high_product := ((state >> 32) * u64(1_103_515_245)) & mask
	low_sum := (low_product & mask) + u64(12_345)
	high_word := ((low_product >> 32) + high_product + (low_sum >> 32)) & mask
	state = (high_word << 32) | (low_sum & mask)
	shifted := u32(state >> 16)
	return shifted % u32(32_767) + u32(1)
}

fn puzzle_rand_int(minimum int, maximum int, mut state u64) int {
	range := maximum - minimum + 1
	draw := puzzle_rand(mut state)
	offset := int(f64(range) * (f64(draw) / 32_768.0))
	if offset == range { return offset + minimum - 1 }
	return offset + minimum
}

fn puzzle_shuffle(mut items []i32, mut state u64) {
	for index := items.len - 1; index > 0; index-- {
		range := index + 1
		draw := puzzle_rand(mut state)
		k := int(f64(range) * (f64(draw) / 32_768.0))
		chosen := if k == range { k - 1 } else { k }
		items[index], items[chosen] = items[chosen], items[index]
	}
}

fn puzzle_find_duplicate(data []i32) i32 {
	mut result := u32(0)
	for index, item in data { result ^= u32(index + 1) ^ u32(item) }
	result ^= u32(data.len)
	return i32(result)
}

fn puzzle_store_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 { unsafe { output[offset + byte] = u8((bits >> u32(byte * 8)) & u32(255)) } }
}

@[export: 'benchmarkgame_puzzle']
pub fn benchmarkgame_puzzle(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	raw_size := unsafe { input[0] }
	raw_rounds := unsafe { input[1] }
	raw_scans := unsafe { input[2] }
	if raw_size < 1 || raw_size > max_array_size || raw_rounds < 1 || raw_rounds > max_rounds ||
		raw_scans < 1 || raw_scans > max_scans_per_array { return -1 }
	size := int(raw_size)
	rounds := int(raw_rounds)
	scans := int(raw_scans)
	output_bytes := rounds * 4
	if output_capacity < usize(output_bytes) || (output_bytes != 0 && unsafe { output == nil }) { return -2 }

	mut random_state := u64(1)
	for round in 0 .. rounds {
		mut data := []i32{len: size + 1}
		for index in 0 .. size + 1 { data[index] = i32(index) }
		data[0] = i32(puzzle_rand_int(1, size, mut random_state))
		puzzle_shuffle(mut data, mut random_state)
		mut duplicate := i32(0)
		for _ in 0 .. scans { duplicate = puzzle_find_duplicate(data) }
		puzzle_store_i32_le(mut output, round * 4, duplicate)
	}
	return i64(output_bytes)
}
