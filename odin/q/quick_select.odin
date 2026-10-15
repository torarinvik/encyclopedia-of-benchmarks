package quick_select

import "core:c"

MAX_VALUES :: 1024

median_of_three :: proc "contextless" (first, middle, last: i64) -> i64 {
	if first < middle {
		if middle < last { return middle }
		if first < last { return last }
		return first
	}
	if first < last { return first }
	if middle < last { return last }
	return middle
}

@(export)
quick_select :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_VALUES) do return -1
	scratch: [MAX_VALUES]i64
	for index := 0; index < int(length); index += 1 { scratch[index] = values[index] }

	target := int(length) / 2
	low := 0
	high := int(length)
	for high - low > 1 {
		middle := low + (high - low) / 2
		pivot := median_of_three(scratch[low], scratch[middle], scratch[high - 1])
		less := low
		scan := low
		greater := high
		for scan < greater {
			if scratch[scan] < pivot {
				scratch[less], scratch[scan] = scratch[scan], scratch[less]
				less += 1
				scan += 1
			} else if scratch[scan] > pivot {
				greater -= 1
				scratch[scan], scratch[greater] = scratch[greater], scratch[scan]
			} else {
				scan += 1
			}
		}
		if target < less { high = less }
		else if target >= greater { low = greater }
		else { return pivot }
	}
	return scratch[target]
}
