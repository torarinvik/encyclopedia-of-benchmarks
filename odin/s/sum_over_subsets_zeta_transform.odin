package sum_over_subsets_zeta_transform

import "core:c"

MAX_STATES :: 64
MAX_INPUT_LENGTH :: c.size_t(MAX_STATES + 2)

@(export)
sum_over_subsets_zeta_transform :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	bit_count := input[0]
	if bit_count < 0 || bit_count > 6 do return -1
	state_count := 1 << int(bit_count)
	if length != c.size_t(state_count+1) do return -1

	transformed: [MAX_STATES]i64
	for mask := 0; mask < state_count; mask += 1 {
		value := input[mask+1]
		if value < 0 || value > 1_000_000 do return -1
		transformed[mask] = value
	}
	for bit_index := 0; bit_index < int(bit_count); bit_index += 1 {
		bit := 1 << bit_index
		for mask := 0; mask < state_count; mask += 1 {
			if (mask & bit) != 0 do transformed[mask] += transformed[mask^bit]
		}
	}
	checksum: i64 = 0
	for mask := 0; mask < state_count; mask += 1 {
		checksum += i64(mask+1) * transformed[mask]
	}
	return checksum
}
