module move_zeroes

const max_length = 4096

fn write_i32_le(output &u8, index usize, value i64) {
	unsafe {
		bits := u32(i32(value))
		for byte in 0 .. 4 { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
	}
}

// Stable nonzero compaction followed by a zero-fill pass.
@[export: 'move_zeroes']
pub fn move_zeroes(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	unsafe {
		for index in 0 .. length {
			value := input[index]
			if value < -2147483648 || value > 2147483647 { return -1 }
		}
		output_bytes := length * 4
		if output_capacity < output_bytes || (output_bytes != 0 && output == nil) { return -2 }
		mut write_index := usize(0)
		for index in 0 .. length {
			value := input[index]
			if value != 0 { write_i32_le(output, write_index, value); write_index++ }
		}
		for write_index < length { write_i32_le(output, write_index, 0); write_index++ }
		return i64(length)
	}
}
