package square_free_factor_list

import "core:c"

// Check that an integer factor list has no repeated values.
@(export)
square_free_factor_list :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 || (length != 0 && values == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if values[i] < -2_147_483_648 || values[i] > 2_147_483_647 do return -1
		for j := c.size_t(0); j < i; j += 1 {
			if values[i] == values[j] do return 0
		}
	}
	return 1
}
