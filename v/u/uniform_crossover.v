module uniform_crossover

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> (8 * byte)) & 255)
		}
	}
}

@[export: 'uniform_crossover']
pub fn uniform_crossover(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 4 || length > 193 { return -1 }
	n := input[0]
	if n < 1 || n > 64 || length != usize(1 + 3 * n) { return -1 }
	for i in 0 .. int(n) {
		if input[1 + i] != 0 && input[1 + i] != 1 { return -1 }
	}
	for i in 0 .. int(2 * n) {
		gene := input[1 + int(n) + i]
		if gene < -2147483648 || gene > 2147483647 { return -1 }
	}
	count := int(n)
	bytes := count * 16
	if capacity < usize(bytes) { return -2 }
	for i in 0 .. count {
		alpha := input[1 + i]
		parent_one := input[1 + count + i]
		parent_two := input[1 + 2 * count + i]
		mut child_one := parent_one
		mut child_two := parent_two
		if alpha == 0 {
			child_one = parent_two
			child_two = parent_one
		}
		put_i64_le(mut output, i * 8, child_one)
		put_i64_le(mut output, (count + i) * 8, child_two)
	}
	return i64(bytes)
}
