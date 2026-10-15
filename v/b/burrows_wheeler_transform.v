module burrows_wheeler_transform

fn rotation_less(values &i64, n int, left int, right int) bool {
	for offset in 0 .. n {
		a := unsafe { values[1 + (left + offset) % n] }
		b := unsafe { values[1 + (right + offset) % n] }
		if a != b { return a < b }
	}
	return left < right
}

@[export: 'burrows_wheeler_transform']
pub fn burrows_wheeler_transform(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	length_value := unsafe { values[0] }
	if length_value < 1 || length_value > 256 { return -1 }
	n := int(length_value)
	if length != usize(n + 1) { return -1 }
	for i := usize(1); i < length; i++ {
		value := unsafe { values[i] }
		if value < 0 || value > 127 { return -1 }
	}
	output_length := n + 4
	if output_capacity < usize(output_length) { return -2 }

	mut order := [256]usize{}
	for i in 0 .. n { order[i] = usize(i) }
	for i in 1 .. n {
		key := order[i]
		mut position := i
		for position > 0 && rotation_less(values, n, int(key), int(order[position - 1])) {
			order[position] = order[position - 1]
			position--
		}
		order[position] = key
	}

	mut primary_index := 0
	for row in 0 .. n { if order[row] == 0 { primary_index = row } }
	encoded_index := u32(primary_index)
	unsafe {
		for byte in 0 .. 4 { output[byte] = u8((encoded_index >> (8 * byte)) & 0xff) }
		for row in 0 .. n {
			start := int(order[row])
			output[4 + row] = u8(values[1 + (start + n - 1) % n])
		}
	}
	return i64(output_length)
}
