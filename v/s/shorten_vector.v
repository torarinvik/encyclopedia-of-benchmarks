module shorten_vector

fn is_removed(value i64, input &i64, n int, by int) bool {
	if by == 0 { return true }
	unsafe {
		for key in n - by .. n {
			if value == input[2 + key] { return true }
		}
	}
	return false
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'shorten_vector']
pub fn shorten_vector(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
	unsafe {
		raw_n := input[0]
		raw_by := input[1]
		if raw_n < 0 || raw_n > 64 || raw_by < 0 || raw_by > raw_n { return -1 }
		n := int(raw_n)
		by := int(raw_by)
		if length != usize(2 + n) { return -1 }
		for i in 0 .. n {
			if input[2 + i] < -1_000_000 || input[2 + i] > 1_000_000 { return -1 }
		}

		mut survivor_count := 0
		for i in 0 .. n {
			if !is_removed(input[2 + i], input, n, by) { survivor_count++ }
		}
		bytes := survivor_count * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }

		mut written := 0
		for i in 0 .. n {
			value := input[2 + i]
			if !is_removed(value, input, n, by) {
				put_i64_le(mut output, written * 8, value)
				written++
			}
		}
		return i64(bytes)
	}
}
