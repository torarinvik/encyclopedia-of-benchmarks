module max_difference_pair

struct Pair {
	small i64
	big   i64
}

fn solve(values []i64) Pair {
	if values.len == 1 { return Pair{values[0], values[0]} }
	left_n := values.len / 2
	left := solve(values[..left_n])
	right := solve(values[left_n..])
	mut min_left := values[0]
	mut max_right := values[left_n]
	for v in values[1..left_n] { if v < min_left { min_left = v } }
	for v in values[left_n + 1..] { if v > max_right { max_right = v } }
	cross := max_right - min_left
	right_diff := right.big - right.small
	left_diff := left.big - left.small
	if right_diff > cross && right_diff > left_diff { return right }
	if left_diff > cross { return left }
	return Pair{min_left, max_right}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 {
		unsafe { output[offset + b] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'max_difference_pair']
pub fn max_difference_pair(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		n64 := input[0]
		if n64 < 1 || n64 > 128 || length != usize(n64) + 1 { return -1 }
		n := int(n64)
		for i in 0 .. n { if input[i+1] < -1000000 || input[i+1] > 1000000 { return -1 } }
		if output == nil || capacity < 16 { return -2 }
		values := []i64{unsafe { input[1..n+1] }}
		result := solve(values)
		put_i64_le(mut output, 0, result.small)
		put_i64_le(mut output, 8, result.big)
		return 16
	}
}
