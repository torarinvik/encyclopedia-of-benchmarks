module resize

const max_input_length = usize(3077)
const max_output_bytes = usize(3072)

@[export: 'resize']
pub fn resize(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	src_width := unsafe { input[0] }
	src_height := unsafe { input[1] }
	dst_width := unsafe { input[2] }
	dst_height := unsafe { input[3] }
	if src_width < 1 || src_width > 32 || src_height < 1 || src_height > 32 ||
		dst_width < 1 || dst_width > 32 || dst_height < 1 || dst_height > 32 { return -1 }

	expected_length := usize(4 + 3 * src_width * src_height)
	if length != expected_length { return -1 }
	for i := usize(4); i < expected_length; i++ {
		if unsafe { input[i] < 0 || input[i] > 255 } { return -1 }
	}

	needed := usize(3 * dst_width * dst_height)
	if needed > max_output_bytes { return -1 }
	if unsafe { output == nil } || capacity < needed { return -2 }

	ratio_x := f64(src_width) / f64(dst_width)
	ratio_y := f64(src_height) / f64(dst_height)
	mut out := usize(0)
	for y in 0 .. int(dst_height) {
		src_y := int(ratio_y * f64(y))
		for x in 0 .. int(dst_width) {
			src_x := int(ratio_x * f64(x))
			src := usize(4 + 3 * (i64(src_y) * src_width + i64(src_x)))
			unsafe {
				output[out] = u8(input[src])
				output[out + 1] = u8(input[src + 1])
				output[out + 2] = u8(input[src + 2])
			}
			out += 3
		}
	}
	return i64(needed)
}
