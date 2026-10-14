package bead_sort

import "core:c"

@(export)
bead_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for level := c.size_t(0); level < 64; level += 1 {
		scratch[level] = 0
	}
	for index := c.size_t(0); index < length; index += 1 {
		for level := i64(0); level < values[index]; level += 1 {
			scratch[c.size_t(level)] += 1
		}
	}
	for index := c.size_t(0); index < length; index += 1 {
		row_from_bottom := length - 1 - index
		value := i64(0)
		for level := c.size_t(0); level < 64; level += 1 {
			if scratch[level] > i64(row_from_bottom) {
				value += 1
			}
		}
		values[index] = value
	}
}
