package reversort

import "core:c"

@(export)
reversort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 { return }
	for index := c.size_t(0); index + 1 < length; index += 1 {
		minimum := index
		for probe := index + 1; probe < length; probe += 1 {
			if values[probe] < values[minimum] { minimum = probe }
		}
		left := index
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
