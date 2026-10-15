module wiggle_sort

const max_array_length = 4096

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'wiggle_sort']
pub fn wiggle_sort(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	mut values := [max_array_length]i64{init: 0}
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = value
	}
	mut wave_index := 1
	for wave_index < int(length) {
		if (wave_index % 2 == 1 && values[wave_index - 1] > values[wave_index]) || (wave_index % 2 == 0 && values[wave_index - 1] < values[wave_index]) {
			temporary := values[wave_index]
			values[wave_index] = values[wave_index - 1]
			values[wave_index - 1] = temporary
		}
		wave_index++
	}
	bytes := length * 4
	if output_capacity < bytes { return -2 }
	for out_index in 0 .. length { store_i32_le(output, int(out_index * 4), values[out_index]) }
	return i64(length)
}
