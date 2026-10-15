module extended_euclidean_algorithm

// Iterative extended Euclid for positive signed-32-bit inputs.
fn store_i32(value i64, output &u8, position usize) usize {
	mut magnitude := u64(value)
	if value < 0 { magnitude = u64(-value) }
	mut bits := magnitude
	if value < 0 { bits = u64(4294967296) - magnitude }
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8(bits % 256) }
		bits /= 256
	}
	return position + 4
}

@[export: 'extended_euclidean_algorithm']
pub fn extended_euclidean_algorithm(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	first := unsafe { input[0] }
	second := unsafe { input[1] }
	if first < 1 || first > 2147483647 || second < 1 || second > 2147483647 { return -1 }
	if output_capacity < 12 { return -2 }

	mut old_r := first
	mut remainder := second
	mut old_x := i64(1)
	mut x := i64(0)
	mut old_y := i64(0)
	mut y := i64(1)
	for remainder != 0 {
		quotient := old_r / remainder
		next_r := old_r - quotient * remainder
		old_r = remainder
		remainder = next_r
		next_x := old_x - quotient * x
		old_x = x
		x = next_x
		next_y := old_y - quotient * y
		old_y = y
		y = next_y
	}
	if old_r > 2147483647 || old_x < -2147483648 || old_x > 2147483647 ||
		old_y < -2147483648 || old_y > 2147483647 { return -1 }
	mut written := usize(0)
	written = store_i32(old_r, output, written)
	written = store_i32(old_x, output, written)
	written = store_i32(old_y, output, written)
	if written == 12 { return 3 }
	return -1
}
