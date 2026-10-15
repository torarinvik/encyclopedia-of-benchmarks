package find_duplicate_number

import "core:c"

// Find the cycle entrance induced by the duplicate value.
@(export)
find_duplicate_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 100001 do return -1
	maximum_value := length - 1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 1 || u64(values[index]) > u64(maximum_value) do return -1
	}

	slow := c.size_t(values[0])
	fast := slow
	for {
		slow = c.size_t(values[slow])
		fast = c.size_t(values[c.size_t(values[fast])])
		if slow == fast do break
	}

	slow = c.size_t(values[0])
	for slow != fast {
		slow = c.size_t(values[slow])
		fast = c.size_t(values[fast])
	}
	return i64(slow)
}
