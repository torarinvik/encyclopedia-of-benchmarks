package external_merge_sorter

import "core:c"

MAX_VALUES :: 4096

merge_pass :: proc(source, destination: [^]i64, length, width: int) {
	start := 0
	for start < length {
		middle := min(start + width, length)
		end_index := min(middle + width, length)
		left, right, output := start, middle, start
		for left < middle && right < end_index {
			if source[left] < source[right] {
				destination[output] = source[left]
				left += 1
			} else {
				destination[output] = source[right]
				right += 1
			}
			output += 1
		}
		for left < middle { destination[output] = source[left]; left += 1; output += 1 }
		for right < end_index { destination[output] = source[right]; right += 1; output += 1 }
		start += width * 2
	}
}

@(export)
external_merge_sorter :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_VALUES) || (length != 0 && values == nil) do return -1
	n := int(length)
	output_bytes := n * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2

	primary: [MAX_VALUES]i64
	temporary: [MAX_VALUES]i64
	for index := 0; index < n; index += 1 { primary[index] = values[index] }
	source := &primary[0]
	destination := &temporary[0]
	for width := 1; width < n; {
		merge_pass(source, destination, n, width)
		source, destination = destination, source
		if width > n / 2 { break }
		width *= 2
	}
	for index := 0; index < n; index += 1 {
		bits := u64(source[index])
		for byte := 0; byte < 8; byte += 1 {
			output[index * 8 + byte] = u8((bits >> u64(byte * 8)) & 255)
		}
	}
	return i64(output_bytes)
}
