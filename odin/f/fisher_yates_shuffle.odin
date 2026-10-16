package fisher_yates_shuffle

import "core:c"

@(export)
fisher_yates_shuffle :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	MAX_VALUES :: 1024
	MODULUS :: u64(2_147_483_647)
	if input == nil || length < 1 || length > c.size_t(MAX_VALUES+1) do return -1
	seed := input[0]
	if seed < 1 || seed >= 2_147_483_647 do return -1
	count := int(length-1)
	values: [MAX_VALUES]i32
	for i := 0; i < count; i += 1 {
		value := input[i+1]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		values[i] = i32(value)
	}
	byte_count := c.size_t(count*4)
	if output_capacity < byte_count || (byte_count != 0 && output == nil) do return -2
	state := u64(seed)
	remaining := count
	for remaining >= 2 {
		state = (state * 48_271) % MODULUS
		other := int(state % u64(remaining))
		temporary := values[remaining-1]
		values[remaining-1] = values[other]
		values[other] = temporary
		remaining -= 1
	}
	for i := 0; i < count; i += 1 {
		bits := u32(values[i])
		for byte := 0; byte < 4; byte += 1 {
			output[i*4+byte] = u8((bits >> u32(byte*8)) & 255)
		}
	}
	return i64(count)
}
