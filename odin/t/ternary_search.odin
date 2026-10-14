package ternary_search

import "core:c"

// Ternary search in an ascending sequence for the shared benchmark contract.
@(export)
ternary_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	low := c.size_t(0)
	high := length
	for low < high {
		third := (high - low) / 3
		first := low + third
	second := high - third - 1
		first_value := values[first]
		second_value := values[second]
		if first_value == target do return i64(first)
		if second_value == target do return i64(second)
		if target < first_value {
			high = first
		} else if target > second_value {
			low = second + 1
		} else {
			low = first + 1
			high = second
		}
	}
	return -1
}
