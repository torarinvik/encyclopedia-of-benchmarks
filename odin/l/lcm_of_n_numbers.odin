package lcm_of_n_numbers

import "core:c"

// Fold a list of nonnegative values with overflow-safe Euclidean LCM.
@(export)
lcm_of_n_numbers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] == 0 do return 0
	}
	accumulator := u64(1)
	maximum := u64(9223372036854775807)
	for index := c.size_t(0); index < length; index += 1 {
		value := u64(values[index])
		left := accumulator
		right := value
		for right != 0 {
			remainder := left % right
			left = right
			right = remainder
		}
		reduced := accumulator / left
		if reduced > maximum / value do return -1
		accumulator = reduced * value
	}
	return i64(accumulator)
}
