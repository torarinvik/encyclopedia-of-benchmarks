module interpolation_search

// Interpolation search in an ascending sequence for the shared benchmark contract.
@[export: 'interpolation_search']
pub fn interpolation_search(values &i64, length usize, target i64) i64 {
	if length == 0 {
		return -1
	}
	mut low := usize(0)
	mut high := length - 1
	for low <= high {
		low_value := unsafe { values[low] }
		high_value := unsafe { values[high] }
		if target < low_value || target > high_value {
			return -1
		}
		if low_value == high_value {
			if low_value == target {
				return i64(low)
			}
			return -1
		}
		numerator := (target - low_value) * i64(high - low)
		denominator := high_value - low_value
		position := low + usize(numerator / denominator)
		value := unsafe { values[position] }
		if value == target {
			return i64(position)
		}
		if value < target {
			low = position + 1
		} else {
			if position == 0 {
				return -1
			}
			high = position - 1
		}
	}
	return -1
}
