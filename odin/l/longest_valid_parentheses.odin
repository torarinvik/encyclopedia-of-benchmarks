package longest_valid_parentheses

import "core:c"

MAX_LENGTH :: 4096

// Memoized endpoint recurrence, evaluated bottom-up from right to left.
@(export)
longest_valid_parentheses :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] != 40 && input[index] != 41 do return -1
	}
	end_exclusive: [MAX_LENGTH]c.size_t = {}
	best := c.size_t(0)
	for remaining := length; remaining > 0; remaining -= 1 {
		index := remaining - 1
		if input[index] == 40 {
			if index + 1 < length && input[index + 1] == 41 {
				end_exclusive[index] = index + 2
				if index + 2 < length && end_exclusive[index + 2] > end_exclusive[index] {
					end_exclusive[index] = end_exclusive[index + 2]
				}
			} else if index + 1 < length {
				nested_end := end_exclusive[index + 1]
				if nested_end > 0 && nested_end < length && input[nested_end] == 41 {
					end_exclusive[index] = nested_end + 1
					if nested_end + 1 < length && end_exclusive[nested_end + 1] > end_exclusive[index] {
						end_exclusive[index] = end_exclusive[nested_end + 1]
					}
				}
			}
		}
		if end_exclusive[index] > index && end_exclusive[index] - index > best {
			best = end_exclusive[index] - index
		}
	}
	return i64(best)
}
