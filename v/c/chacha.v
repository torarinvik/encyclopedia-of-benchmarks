const chacha_words = 16
const chacha_bytes = 64
const word_mask = u64(0xffff_ffff)

fn rotate_left(value u64, count u64) u64 {
	return ((value << count) | (value >> (32 - count))) & word_mask
}

fn quarter_round(mut state [16]u64, a int, b int, c int, d int) {
	state[a] = (state[a] + state[b]) & word_mask
	state[d] = rotate_left(state[d] ^ state[a], 16)
	state[c] = (state[c] + state[d]) & word_mask
	state[b] = rotate_left(state[b] ^ state[c], 12)
	state[a] = (state[a] + state[b]) & word_mask
	state[d] = rotate_left(state[d] ^ state[a], 8)
	state[c] = (state[c] + state[d]) & word_mask
	state[b] = rotate_left(state[b] ^ state[c], 7)
}

@[export: 'chacha']
pub fn chacha(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != chacha_words { return -1 }
	mut initial := [16]u64{}
	for index in 0 .. chacha_words {
		value := unsafe { values[index] }
		if value < 0 || value > 0xffff_ffff { return -1 }
		initial[index] = u64(value)
	}
	if unsafe { output == nil } || output_capacity < chacha_bytes { return -2 }

	mut state := initial
	for _ in 0 .. 10 {
		quarter_round(mut state, 0, 4, 8, 12)
		quarter_round(mut state, 1, 5, 9, 13)
		quarter_round(mut state, 2, 6, 10, 14)
		quarter_round(mut state, 3, 7, 11, 15)
		quarter_round(mut state, 0, 5, 10, 15)
		quarter_round(mut state, 1, 6, 11, 12)
		quarter_round(mut state, 2, 7, 8, 13)
		quarter_round(mut state, 3, 4, 9, 14)
	}
	for index in 0 .. chacha_words {
		word := (state[index] + initial[index]) & word_mask
		unsafe {
			output[4 * index] = u8(word & 0xff)
			output[4 * index + 1] = u8((word >> 8) & 0xff)
			output[4 * index + 2] = u8((word >> 16) & 0xff)
			output[4 * index + 3] = u8((word >> 24) & 0xff)
		}
	}
	return chacha_bytes
}
