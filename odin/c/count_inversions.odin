package count_inversions

import "core:c"

// Count strict inversions with bottom-up merge sort.
@(export)
count_inversions :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	max_length :: 4096
	if length > c.size_t(max_length) || (length > 0 && values == nil) do return -1
	if length < 2 do return 0

	var source: [max_length]i64
	var scratch: [max_length]i64
	for i := 0; i < int(length); i += 1 do source[i] = values[i]

	inversions := i64(0)
	width := 1
	for width < int(length) {
		low := 0
		for low < int(length) {
			middle := min(low + width, int(length))
			high := min(middle + width, int(length))
			left, right, output := low, middle, low
			for left < middle && right < high {
				if source[left] <= source[right] {
					scratch[output] = source[left]
					left += 1
				} else {
					scratch[output] = source[right]
					right += 1
					inversions += i64(middle - left)
				}
				output += 1
			}
			for left < middle {
				scratch[output] = source[left]
				left += 1
				output += 1
			}
			for right < high {
				scratch[output] = source[right]
				right += 1
				output += 1
			}
			low = high
		}
		for i := 0; i < int(length); i += 1 do source[i] = scratch[i]
		width *= 2
	}
	return inversions
}
