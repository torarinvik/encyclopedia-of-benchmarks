package minimum_waiting_time

import "core:c"

@(export)
minimum_waiting_time :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 64 || (length > 0 && values == nil) do return -9223372036854775807 - 1
	if length == 0 do return 0
	durations: [64]i64 = {}
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 0 || value > 1000 do return -9223372036854775807 - 1
		durations[index] = value
	}
	for index := 1; index < int(length); index += 1 {
		key := durations[index]
		cursor := index
		for cursor > 0 && durations[cursor - 1] > key {
			durations[cursor] = durations[cursor - 1]
			cursor -= 1
		}
		durations[cursor] = key
	}
	total := i64(0)
	for index := 0; index < int(length); index += 1 {
		total += durations[index] * i64(int(length) - index - 1)
	}
	return total
}
