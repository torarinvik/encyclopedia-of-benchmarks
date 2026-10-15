module burrows_wheeler_transform_case_insensitive

fn fold_ascii(value i64) u8 {
	byte := u8(value)
	if byte >= u8(`A`) && byte <= u8(`Z`) { return byte + u8(32) }
	return byte
}

fn rotation_less(values &i64, n int, left int, right int) bool {
	for offset in 0 .. n {
		a := fold_ascii(unsafe { values[1 + (left + offset) % n] })
		b := fold_ascii(unsafe { values[1 + (right + offset) % n] })
		if a != b { return a < b }
	}
	return left < right
}

fn rotation_equals_input(values &i64, n int, start int) bool {
	for offset in 0 .. n {
		if unsafe { values[1 + (start + offset) % n] } != unsafe { values[1 + offset] } { return false }
	}
	return true
}

@[export: 'burrows_wheeler_transform_case_insensitive']
pub fn burrows_wheeler_transform_case_insensitive(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 { return -1 }
	length_value := unsafe { values[0] }
	if length_value < 0 || length_value > 256 { return -1 }
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
	for row in 0 .. n {
		if rotation_equals_input(values, n, int(order[row])) { primary_index = row }
	}
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
