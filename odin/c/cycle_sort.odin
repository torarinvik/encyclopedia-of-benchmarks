package cycle_sort

import "core:c"

@(export)
cycle_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	cycle_start := c.size_t(0)
	for cycle_start < length - 1 {
		item := values[cycle_start]
		position := cycle_start
		for scan := cycle_start + 1; scan < length; scan += 1 {
			if values[scan] < item {
				position += 1
			}
		}
		if position != cycle_start {
			for position < length && item == values[position] {
				position += 1
			}
			if position < length {
				temporary := values[position]
				values[position] = item
				item = temporary
				for position != cycle_start {
					position = cycle_start
					for scan := cycle_start + 1; scan < length; scan += 1 {
						if values[scan] < item {
							position += 1
						}
					}
					for position < length && item == values[position] {
						position += 1
					}
					if position == length {
						break
					}
					temporary = values[position]
					values[position] = item
					item = temporary
				}
			}
		}
		cycle_start += 1
	}
}
