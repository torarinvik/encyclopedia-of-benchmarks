package z_algorithm_search

import "core:c"

@(export)
z_algorithm_search :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 do return -1
	if values[0] < 0 || values[0] > 2047 || values[1] < 0 || values[1] > 2047 do return -1
	text_length := int(values[0]); pattern_length := int(values[1])
	if length != c.size_t(2 + text_length + pattern_length) do return -1
	for i := 2; i < int(length); i += 1 { if values[i] < 0 || values[i] > 127 do return -1 }
	if pattern_length == 0 {
		count := text_length + 1
		if output_capacity < c.size_t(4 * count) || output == nil do return -2
		for i := 0; i < count; i += 1 {
			position := u32(i + 1)
			for b := 0; b < 4; b += 1 do output[4 * i + b] = u8((position >> u32(8 * b)) & 0xff)
		}
		return i64(count)
	}
	sequence: [4095]u32
	z: [4095]int
	total := pattern_length + 1 + text_length
	for i := 0; i < pattern_length; i += 1 {
		value := u32(values[2 + text_length + i])
		if value >= u32('A') && value <= u32('Z') do value += 32
		sequence[i] = value; z[i] = 0
	}
	sequence[pattern_length] = 256; z[pattern_length] = 0
	for i := 0; i < text_length; i += 1 {
		value := u32(values[2 + i])
		if value >= u32('A') && value <= u32('Z') do value += 32
		sequence[pattern_length + 1 + i] = value; z[pattern_length + 1 + i] = 0
	}
	left := 0; right := 0
	for i := 1; i < total; i += 1 {
		if i < right {
			remaining := right - i
			if z[i - left] < remaining { z[i] = z[i - left] } else { z[i] = remaining }
		}
		for i + z[i] < total && sequence[z[i]] == sequence[i + z[i]] { z[i] += 1 }
		if i + z[i] > right { left = i; right = i + z[i] }
	}
	count := 0
	for i := pattern_length + 1; i < total; i += 1 { if z[i] >= pattern_length do count += 1 }
	if output_capacity < c.size_t(4 * count) || (count > 0 && output == nil) do return -2
	write := 0
	for i := pattern_length + 1; i < total; i += 1 {
		if z[i] >= pattern_length {
			position := u32(i - pattern_length)
			for b := 0; b < 4; b += 1 do output[4 * write + b] = u8((position >> u32(8 * b)) & 0xff)
			write += 1
		}
	}
	return i64(count)
}
