package subset_count

import "core:c"

MAX_INPUT_LENGTH :: c.size_t(33)

@(export)
subset_count :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	count_value, target := values[0], values[1]
	if count_value < 1 || count_value > 30 || target < 0 || target > 64 do return -1
	count := int(count_value)
	if int(length) != count + 2 do return -1

	for index := 0; index < count; index += 1 {
		value := values[2 + index]
		if value < 0 || value > 64 do return -1
	}

	previous: [65]i64 = {}
	previous[0] = 1
	if values[2] <= target do previous[int(values[2])] = 1

	for index := 1; index < count; index += 1 {
		current: [65]i64 = {}
		current[0] = 1
		for amount := 1; amount <= int(target); amount += 1 {
			value := values[2 + index]
			not_taken := previous[amount]
			taken: i64 = 0
			if value <= i64(amount) do taken = previous[amount - int(value)]
			current[amount] = not_taken + taken
		}
		previous = current
	}
	return previous[int(target)]
}
