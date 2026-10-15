package adaptive_merge_sort

import "core:c"

MAX_VALUES :: 1024

adaptive_merge_sort_range :: proc "contextless" (values, scratch: [^]i64, low, high: int) {
	if high-low <= 1 { return }
	middle := low + (high-low) / 2
	adaptive_merge_sort_range(values, scratch, low, middle)
	adaptive_merge_sort_range(values, scratch, middle, high)
	if values[middle - 1] <= values[middle] { return }
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
	for left < middle { scratch[output] = values[left]; left += 1; output += 1 }
	for right < high { scratch[output] = values[right]; right += 1; output += 1 }
	for index := low; index < high; index += 1 { values[index] = scratch[index] }
}

@(export)
adaptive_merge_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	scratch: [MAX_VALUES]i64
	if length > c.size_t(MAX_VALUES) { return }
	adaptive_merge_sort_range(values, &scratch[0], 0, int(length))
}
