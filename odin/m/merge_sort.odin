package merge_sort

import "core:c"

@(export)
merge_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	width := c.size_t(1)
	for width < length {
		low := c.size_t(0)
		for low < length {
			middle := low + width
			if middle > length {
				middle = length
			}
			high := middle + width
			if high > length {
				high = length
			}
			left := low
			right := middle
			output := low
			for left < middle && right < high {
				if values[left] <= values[right] {
					scratch[output] = values[left]
					left += 1
				} else {
					scratch[output] = values[right]
					right += 1
				}
				output += 1
			}
			for left < middle {
				scratch[output] = values[left]
				left += 1
				output += 1
			}
			for right < high {
				scratch[output] = values[right]
				right += 1
				output += 1
			}
			for index := low; index < high; index += 1 {
				values[index] = scratch[index]
			}
			low = high
		}
		if width > length / 2 {
			break
		}
		width *= 2
	}
}
