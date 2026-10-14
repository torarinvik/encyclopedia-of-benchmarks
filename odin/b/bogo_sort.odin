package bogo_sort

import "core:c"

@(export)
bogo_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	state: u64 = 2654435769
	for {
		sorted := true
		for check_index := c.size_t(1); check_index < length; check_index += 1 {
			if values[check_index-1] > values[check_index] {
				sorted = false
				break
			}
		}
		if sorted {
			break
		}
		index := length
		for index > 1 {
			index -= 1
			state = (state*1664525 + 1013904223) % 4294967296
			other := c.size_t((state / 65536) % u64(index+1))
			temporary := values[index]
			values[index] = values[other]
			values[other] = temporary
		}
	}
}
