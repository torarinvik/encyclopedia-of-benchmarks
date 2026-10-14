module ternary_search

// Ternary search in an ascending sequence for the shared benchmark contract.
@[export: 'ternary_search']
pub fn ternary_search(values &i64, length usize, target i64) i64 {
	mut low := usize(0)
	mut high := length
	for low < high {
		third := (high - low) / 3
		first := low + third
		second := high - third - 1
		first_value := unsafe { values[first] }
		second_value := unsafe { values[second] }
		if first_value == target {
			return i64(first)
		}
		if second_value == target {
			return i64(second)
		}
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
