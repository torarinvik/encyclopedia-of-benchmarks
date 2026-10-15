package binary_to_base64

import "core:c"

@(export)
binary_to_base64 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 1 || input[0] > 256 do return -1
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
	for i: usize = begin; i < end; i += 1 { if input[1 + i] != 48 && input[1 + i] != 49 do return -1 }
	bit_count := end - begin
	padding := 6 - bit_count % 6
	groups := (bit_count + padding) / 6
	output_length := groups
	if negative { output_length += 1 }
	if capacity < output_length || output == nil do return -2
	alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	offset: usize = 0
	if negative { output[offset] = u8('-'); offset += 1 }
	for group: usize = 0; group < groups; group += 1 {
		value: u32 = 0
		for bit: usize = 0; bit < 6; bit += 1 {
			value <<= 1
			position := group * 6 + bit
			if position >= padding && input[1 + begin + position - padding] == 49 { value += 1 }
		}
		output[offset] = u8(alphabet[value])
		offset += 1
	}
	return i64(output_length)
}
