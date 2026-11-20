module hilbert_curve_index_encode

const max_order = i64(8)

fn hilbert_index(order i64, x_value i64, y_value i64) i64 {
	mut current_x := x_value
	mut current_y := y_value
	mut distance := i64(0)
	mut bit_index := order - 1
	for bit_index >= 0 {
		bit := i64(1) << bit_index
		mut x_bit := i64(0)
		mut y_bit := i64(0)
		if (current_x & bit) != 0 { x_bit = 1 }
		if (current_y & bit) != 0 { y_bit = 1 }
		distance += bit * bit * ((3 * x_bit) ^ y_bit)
		mask := bit - 1
		mut low_x := current_x & mask
		mut low_y := current_y & mask
		if y_bit == 0 {
			if x_bit != 0 {
				low_x = mask - low_x
				low_y = mask - low_y
			}
			current_x = low_y
			current_y = low_x
		} else {
			current_x = low_x
			current_y = low_y
		}
		bit_index--
	}
	return distance
}

fn store_i64_le(mut output &u8, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'hilbert_curve_index_encode']
pub fn hilbert_curve_index_encode(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		order := input[0]
		if order < 1 || order > max_order { return -1 }
		side := i64(1) << order
		x, y := input[1], input[2]
		if x < 0 || x >= side || y < 0 || y >= side { return -1 }
		if output == nil || capacity < 8 { return -2 }
		store_i64_le(mut output, hilbert_index(order, x, y))
		return 8
	}
}
