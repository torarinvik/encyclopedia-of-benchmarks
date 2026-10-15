package max_non_adjacent_sum

import "core:c"

@(export)
max_non_adjacent_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807) - 1
	if values == nil || length < 1 || length > 100000 do return invalid
	two_back: i64 = 0
	one_back: i64 = 0
	for i := 0; i < int(length); i += 1 {
		value := values[i]
		if value < 0 || value > 10000 do return invalid
		take := two_back + value
		current := max(take, one_back)
		two_back = one_back
		one_back = current
	}
	return one_back
}
