package interpolation_search

import "core:c"

// Interpolation search in an ascending sequence for the shared benchmark contract.
@(export)
interpolation_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length == 0 do return -1
	low := c.size_t(0)
	high := length - 1
	for low <= high {
		low_value := values[low]
		high_value := values[high]
		if target < low_value || target > high_value do return -1
		if low_value == high_value {
			if low_value == target do return i64(low)
			return -1
		}
		numerator := (target - low_value) * i64(high - low)
		denominator := high_value - low_value
		position := low + c.size_t(numerator / denominator)
		value := values[position]
		if value == target do return i64(position)
		if value < target {
			low = position + 1
		} else {
			if position == 0 do return -1
			high = position - 1
		}
	}
	return -1
}
