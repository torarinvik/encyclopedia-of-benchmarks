package subtract

import "core:c"

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
	for byte := 0; byte < 4; byte += 1 { output[offset + byte] = u8((value >> u32(byte * 8)) & 255) }
}

@(export)
subtract :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 do return -2
	if input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 16 do return -2
	ra, ca := int(input[0]), int(input[1])
	if ra == 0 && ca != 0 do return -2
	na := ra * ca
	bd := 2 + na
	if c.size_t(bd + 2) > length || input[bd] < 0 || input[bd] > 16 || input[bd + 1] < 0 || input[bd + 1] > 16 do return -2
	rb, cb := int(input[bd]), int(input[bd + 1])
	if rb == 0 && cb != 0 do return -2
	nb := rb * cb
	if length != c.size_t(bd + 2 + nb) do return -2
	if ra != rb || ca != cb do return -1
	for index := 0; index < na; index += 1 {
		if input[index + 2] < -2_147_483_648 || input[index + 2] > 2_147_483_647 || input[bd + 2 + index] < -2_147_483_648 || input[bd + 2 + index] > 2_147_483_647 do return -2
	}
	if na == 0 do return 0
	if output == nil || output_capacity < c.size_t(na * 4) do return -3
	for index := 0; index < na; index += 1 {
		left := u32(i32(input[index + 2]))
		right := u32(i32(input[bd + 2 + index]))
		store_i32_le(output, index * 4, left - right)
	}
	return i64(na)
}
