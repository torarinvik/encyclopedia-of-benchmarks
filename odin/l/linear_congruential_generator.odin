package linear_congruential_generator

import "core:c"

put_u64_le :: proc(output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(value >> u64(byte * 8)) }
}

@(export)
linear_congruential_generator :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length != 5 do return -1
	seed := input[0]; multiplier := input[1]; increment := input[2]; modulo := input[3]; count := input[4]
	if modulo < 2 || modulo > 4294967296 || seed < 0 || seed >= modulo || multiplier < 0 || multiplier > 65535 || increment < 0 || increment > 4294967295 || count < 0 || count > 512 do return -1
	n := int(count); required := n * 8
	if int(capacity) < required || (required > 0 && output == nil) do return -2
	state := u64(seed)
	for i := 0; i < n; i += 1 {
		state = (u64(multiplier) * state + u64(increment)) % u64(modulo)
		put_u64_le(output, i * 8, state)
	}
	return i64(required)
}
