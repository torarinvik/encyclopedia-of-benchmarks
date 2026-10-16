module external_merge_sorter

const max_values = 4096

fn merge_pass(source []i64, mut destination []i64, length int, width int) {
	mut start := 0
	for start < length {
		middle := min(start + width, length)
		end_index := min(middle + width, length)
		mut left := start
		mut right := middle
		mut output_index := start
		for left < middle && right < end_index {
			if source[left] < source[right] {
				destination[output_index] = source[left]
				left++
			} else {
				destination[output_index] = source[right]
				right++
			}
			output_index++
		}
		for left < middle { destination[output_index] = source[left]; left++; output_index++ }
		for right < end_index { destination[output_index] = source[right]; right++; output_index++ }
		start += width * 2
	}
}

fn store_i64_le(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

// Bottom-up merge passes over two bounded buffers, modeling sequential stores.
@[export: 'external_merge_sorter']
pub fn external_merge_sorter(values &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	if length > max_values || (length != 0 && unsafe { values == nil }) { return -1 }
	output_bytes := int(length) * 8
	if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }

	mut primary := [max_values]i64{}
	mut temporary := [max_values]i64{}
	for index in 0 .. int(length) { primary[index] = unsafe { values[index] } }
	mut primary_is_source := true
	mut width := 1
	for width < int(length) {
		if primary_is_source {
			merge_pass(primary[..], mut temporary[..], int(length), width)
		} else {
			merge_pass(temporary[..], mut primary[..], int(length), width)
		}
		primary_is_source = !primary_is_source
		if width > int(length) / 2 { break }
		width *= 2
	}
	for index in 0 .. int(length) {
		value := if primary_is_source { primary[index] } else { temporary[index] }
		store_i64_le(mut output, index * 8, value)
	}
	return i64(output_bytes)
}
