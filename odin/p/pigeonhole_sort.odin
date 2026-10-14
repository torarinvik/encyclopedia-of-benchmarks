package pigeonhole_sort

import "core:c"

@(export)
pigeonhole_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for bucket := c.size_t(0); bucket < 257; bucket += 1 {
		scratch[bucket] = 0
	}
	for index := c.size_t(0); index < length; index += 1 {
		bucket := c.size_t(values[index] + 128)
		scratch[bucket] += 1
	}
	index := c.size_t(0)
	for bucket := c.size_t(0); bucket < 257; bucket += 1 {
		for scratch[bucket] > 0 {
			values[index] = i64(bucket) - 128
			index += 1
			scratch[bucket] -= 1
		}
	}
}
