module cocktail_shaker_sort

// Stable full-range bidirectional adjacent-swap sort.
@[export: 'cocktail_shaker_sort']
pub fn cocktail_shaker_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		for {
			mut swapped := false
			for index := usize(0); index + 1 < length; index++ {
				if values[index] > values[index + 1] {
					temporary := values[index]
					values[index] = values[index + 1]
					values[index + 1] = temporary
					swapped = true
				}
			}
			if !swapped {
				break
			}
			swapped = false
			mut index := length - 1
			for index > 0 {
				if values[index - 1] > values[index] {
					temporary := values[index - 1]
					values[index - 1] = values[index]
					values[index] = temporary
					swapped = true
				}
				index--
			}
			if !swapped {
				break
			}
		}
	}
}
