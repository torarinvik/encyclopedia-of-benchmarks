module bogo_sort

// Deterministic bogo sort for the shared, bounded portable workload.
@[export: 'bogo_sort']
pub fn bogo_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut state := u64(2654435769)
	unsafe {
		for {
			mut sorted := true
			for check_index := usize(1); check_index < length; check_index++ {
				if values[check_index - 1] > values[check_index] {
					sorted = false
					break
				}
			}
			if sorted {
				break
			}
			mut index := length
			for index > 1 {
				index--
				state = (state * u64(1664525) + u64(1013904223)) % u64(4294967296)
				other := usize((state / u64(65536)) % u64(index + 1))
				temporary := values[index]
				values[index] = values[other]
				values[other] = temporary
			}
		}
	}
}
