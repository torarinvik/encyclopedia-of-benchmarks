module cocktail_sort

// Stable bidirectional bubble sort for signed 64-bit values.
@[export: 'cocktail_sort']
pub fn cocktail_sort(mut values &i64, length usize) {
	mut start := usize(0)
	mut end := length
	for start < end {
		mut swapped := false
		for index := start; index + 1 < end; index++ {
			unsafe {
				if values[index] > values[index + 1] {
					temporary := values[index]
					values[index] = values[index + 1]
					values[index + 1] = temporary
					swapped = true
				}
			}
		}
		if !swapped {
			break
		}
		end--
		swapped = false
		mut index := end
		for index > start {
			unsafe {
				if values[index - 1] > values[index] {
					temporary := values[index - 1]
					values[index - 1] = values[index]
					values[index] = temporary
					swapped = true
				}
			}
			index--
		}
		start++
		if !swapped {
			break
		}
	}
}
