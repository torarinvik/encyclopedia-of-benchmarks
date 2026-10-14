package cocktail_sort

import "core:c"

@(export)
cocktail_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	start := c.size_t(0)
	end := length
	for start < end {
		swapped := false
		for index := start; index + 1 < end; index += 1 {
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
		end -= 1
		swapped = false
		index := end
		for index > start {
			if values[index - 1] > values[index] {
				temporary := values[index - 1]
				values[index - 1] = values[index]
				values[index] = temporary
				swapped = true
			}
			index -= 1
		}
		start += 1
		if !swapped {
			break
		}
	}
}
