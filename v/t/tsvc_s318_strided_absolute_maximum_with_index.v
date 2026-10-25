module tsvc_s318_strided_absolute_maximum_with_index

const max_n = 64
const max_stride = 4
const max_physical_n = 1 + (max_n - 1) * max_stride
const max_input_length = 2 + max_physical_n
const max_value = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s318_strided_absolute_maximum_with_index']
pub fn tsvc_s318_strided_absolute_maximum_with_index(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	stride_raw := unsafe { input[1] }
	if n_raw < 1 || n_raw > max_n || stride_raw < 1 || stride_raw > max_stride { return -1 }
	n := int(n_raw)
	stride := int(stride_raw)
	physical_n := 1 + (n - 1) * stride
	if int(length) != 2 + physical_n { return -1 }
	for i in 0 .. physical_n {
		value := unsafe { input[i + 2] }
		if value < -max_value || value > max_value { return -1 }
	}
	if unsafe { output == nil } || output_capacity < 16 { return -2 }

	first := unsafe { input[2] }
	mut maximum := first
	if maximum < 0 { maximum = -maximum }
	mut maximum_index := 0
	for i in 1 .. n {
		value := unsafe { input[2 + i * stride] }
		mut magnitude := value
		if magnitude < 0 { magnitude = -magnitude }
		if magnitude > maximum {
			maximum = magnitude
			maximum_index = i
		}
	}
	store_i64_le(mut output, 0, maximum)
	store_i64_le(mut output, 8, i64(maximum_index))
	return 2
}
