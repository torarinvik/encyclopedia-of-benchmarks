package base64_to_binary

import "core:c"

@(export)
base64_to_binary :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > 256 do return -1
	n := usize(input[0])
	if length != n + 1 do return -1
	for i: usize = 0; i < n; i += 1 { if input[1 + i] < 0 || input[1 + i] > 127 do return -1 }
	begin: usize = 0
	end := n
	for begin < end {
		v := input[1 + begin]
		if !((v >= 9 && v <= 13) || v == 32) do break
		begin += 1
	}
	for end > begin {
		v := input[end]
		if !((v >= 9 && v <= 13) || v == 32) do break
		end -= 1
	}
	if begin == end do return -1
	negative := input[1 + begin] == 45
	if negative { begin += 1 }
	for i: usize = begin; i < end; i += 1 {
		v := input[1 + i]
		if !((v >= 65 && v <= 90) || (v >= 97 && v <= 122) || (v >= 48 && v <= 57) || v == 43 || v == 47) do return -1
	}
	output_length := (end - begin) * 6
	if negative { output_length += 1 }
	if capacity < output_length || output == nil do return -2
	offset: usize = 0
	if negative { output[offset] = u8('-'); offset += 1 }
	for i: usize = begin; i < end; i += 1 {
		v := input[1 + i]
		value: u32 = 0
		if v >= 65 && v <= 90 { value = u32(v - 65) }
		else if v >= 97 && v <= 122 { value = u32(v - 97 + 26) }
		else if v >= 48 && v <= 57 { value = u32(v - 48 + 52) }
		else if v == 43 { value = 62 }
		else { value = 63 }
		for bit: u32 = 0; bit < 6; bit += 1 {
			output[offset] = u8('0' + ((value >> (5 - bit)) & 1))
			offset += 1
		}
	}
	return i64(output_length)
}
