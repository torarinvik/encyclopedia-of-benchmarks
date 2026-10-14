package gnome_sort

import "core:c"

// Stable gnome sort for the shared mutable in-place sorting contract.
@(export)
gnome_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	position := c.size_t(1)
	for position < length {
		if values[position] >= values[position - 1] {
			position += 1
		} else {
			temporary := values[position - 1]
			values[position - 1] = values[position]
			values[position] = temporary
			if position > 1 {
				position -= 1
			} else {
				position = 1
			}
		}
	}
}
