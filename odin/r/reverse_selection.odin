package reverse_selection

import "core:c"

@(export)
reverse_selection :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for start := c.size_t(0); start+1 < length; start += 1 {
		minimum := start
		for scan := start + 1; scan < length; scan += 1 {
			if values[scan] < values[minimum] {
				minimum = scan
			}
		}
		left := start
		right := minimum
		for left < right {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
			left += 1
			right -= 1
		}
	}
}
