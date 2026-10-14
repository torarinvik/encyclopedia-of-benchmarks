package comb_sort

import "core:c"

shrink_gap :: proc(gap: c.size_t) -> c.size_t {
	return (gap / 13) * 10 + ((gap % 13) * 10) / 13
}

// Comb sort with a rational 10/13 gap shrink factor.
@(export)
comb_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	gap := length
	swapped := true
	for gap > 1 || swapped {
		gap = shrink_gap(gap)
		if gap < 1 do gap = 1
		swapped = false
		for index := c.size_t(0); index < length - gap; index += 1 {
			if values[index] > values[index + gap] {
				temporary := values[index]
				values[index] = values[index + gap]
				values[index + gap] = temporary
				swapped = true
			}
		}
	}
}
