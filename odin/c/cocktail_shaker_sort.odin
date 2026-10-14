package cocktail_shaker_sort

import "core:c"

@(export)
cocktail_shaker_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for {
		swapped := false
		for index := c.size_t(0); index + 1 < length; index += 1 {
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
		index := length - 1
		for index > 0 {
			if values[index - 1] > values[index] {
				temporary := values[index - 1]
				values[index - 1] = values[index]
				values[index] = temporary
				swapped = true
			}
			index -= 1
		}
		if !swapped {
			break
		}
	}
}
