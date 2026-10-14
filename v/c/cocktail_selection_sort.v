module cocktail_selection_sort

@[export: 'cocktail_selection_sort']
pub fn cocktail_selection_sort(mut values &i64, length usize) {
	if length > 1024 {
		return
	}
	mut low := usize(0)
	mut high := length
	for high - low > 1 {
		mut minimum_index := low
		mut maximum_index := low
		for index := low + 1; index < high; index++ {
			if unsafe { values[index] < values[minimum_index] } {
				minimum_index = index
			}
			if unsafe { values[index] > values[maximum_index] } {
				maximum_index = index
			}
		}
		minimum := unsafe { values[minimum_index] }
		unsafe { values[minimum_index] = values[low] }
		unsafe { values[low] = minimum }
		if maximum_index == low {
			maximum_index = minimum_index
		}
		maximum := unsafe { values[maximum_index] }
		unsafe { values[maximum_index] = values[high - 1] }
		unsafe { values[high - 1] = maximum }
		low++
		high--
	}
}
