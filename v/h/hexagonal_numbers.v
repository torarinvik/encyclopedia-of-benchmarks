module hexagonal_numbers

const max_length = 1024
const bytes_per_value = 8

fn store_i64_le(output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'hexagonal_numbers']
pub fn hexagonal_numbers(length i64, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_length { return -1 }
	n := int(length)
	required := usize(n * bytes_per_value)
	if output_capacity < required { return -2 }
	for index in 0 .. n {
		i := i64(index)
		store_i64_le(output, index * bytes_per_value, i * (2 * i - 1))
	}
	return length
}
