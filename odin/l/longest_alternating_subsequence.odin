package longest_alternating_subsequence

import "core:c"

MAX_LENGTH :: 512

// Return the length of a strict longest alternating subsequence.
@(export)
longest_alternating_subsequence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -1
	rising: [MAX_LENGTH]i64
	falling: [MAX_LENGTH]i64
	result := i64(1)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		rising[index] = 1
		falling[index] = 1
		for previous := 0; previous < index; previous += 1 {
			if values[previous] < value && rising[index] < falling[previous] + 1 {
				rising[index] = falling[previous] + 1
			}
			if values[previous] > value && falling[index] < rising[previous] + 1 {
				falling[index] = rising[previous] + 1
			}
		}
		if rising[index] > result do result = rising[index]
		if falling[index] > result do result = falling[index]
	}
	return result
}
