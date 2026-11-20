package myrvold_ruskey_permutation_unrank

import "core:c"

@(export)
myrvold_ruskey_permutation_unrank :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 2 || length > 3 do return -1
	if length != 2 do return -1
	n_value := input[0]
	rank_value := input[1]
	if n_value < 0 || n_value > 8 || rank_value < 0 do return -1
	n := int(n_value)
	factorial: i64 = 1
	for factor := 2; factor <= n; factor += 1 { factorial *= i64(factor) }
	if rank_value >= factorial do return -1

	required := n * 8
	if output == nil || capacity < c.size_t(required) do return -2
	permutation: [8]i64
	for i := 0; i < n; i += 1 { permutation[i] = i64(i) }
	remainder := rank_value
	for size := n; size > 0; size -= 1 {
		choice := int(remainder % i64(size))
		remainder /= i64(size)
		held := permutation[size - 1]
		permutation[size - 1] = permutation[choice]
		permutation[choice] = held
	}
	for i := 0; i < n; i += 1 {
		value := u64(permutation[i])
		for byte := 0; byte < 8; byte += 1 {
			output[i * 8 + byte] = u8((value >> (byte * 8)) & 255)
		}
	}
	return i64(required)
}
