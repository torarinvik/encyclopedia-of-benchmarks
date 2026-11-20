package mrg32k3a_combined_recursive_generator

import "core:c"

M1 :: i64(4_294_967_087)
M2 :: i64(4_294_944_443)
MAX_COUNT :: i64(64)

residue :: proc(value, modulus: i64) -> i64 {
	result := value % modulus
	if result < 0 do result += modulus
	return result
}

put_i64_le :: proc(output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + usize(byte)] = u8(bits >> u64(8 * byte))
	}
}

@(export)
mrg32k3a_combined_recursive_generator :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length != 7 do return -1
	x1: [3]i64
	x2: [3]i64
	for i: usize = 0; i < 3; i += 1 {
		x1[i] = input[i]
		x2[i] = input[i + 3]
		if x1[i] < 0 || x1[i] >= M1 || x2[i] < 0 || x2[i] >= M2 do return -1
	}
	if (x1[0] | x1[1] | x1[2]) == 0 || (x2[0] | x2[1] | x2[2]) == 0 do return -1
	count_value := input[6]
	if count_value < 0 || count_value > MAX_COUNT do return -1
	count := int(count_value)
	required := count * 8
	if count == 0 do return 0
	if capacity < c.size_t(required) || output == nil do return -2

	for step := 0; step < count; step += 1 {
		next1 := residue(1_403_580 * x1[1] - 810_728 * x1[0], M1)
		next2 := residue(527_612 * x2[2] - 1_370_589 * x2[0], M2)
		x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1
		x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2
		z := next1 - next2
		if z < 0 do z += M1
		put_i64_le(output, usize(step * 8), z)
	}
	return i64(required)
}
