package merge_sorter

import "core:c"

MAX_VALUES :: 1024

merge_sorter_range :: proc "contextless" (values, scratch: [^]i64, low, high: int) {
	if high-low <= 1 { return }
	middle := low + (high-low) / 2
	merge_sorter_range(values, scratch, low, middle)
	merge_sorter_range(values, scratch, middle, high)
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
merge_sorter :: proc "c" (values: [^]i64, length: c.size_t) {
	scratch: [MAX_VALUES]i64
	if length > c.size_t(MAX_VALUES) { return }
	merge_sorter_range(values, &scratch[0], 0, int(length))
}
