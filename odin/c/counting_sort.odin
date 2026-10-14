package counting_sort

import "core:c"

@(export)
counting_sort :: proc "c" (values, counts: [^]i64, length: c.size_t) {
	for bucket := c.size_t(0); bucket < 257; bucket += 1 {
		counts[bucket] = 0
	}
	for index := c.size_t(0); index < length; index += 1 {
		bucket := c.size_t(values[index] + 128)
		counts[bucket] += 1
	}
	output := c.size_t(0)
	for bucket := c.size_t(0); bucket < 257; bucket += 1 {
		for counts[bucket] > 0 {
			values[output] = i64(bucket) - 128
			output += 1
			counts[bucket] -= 1
		}
	}
}
