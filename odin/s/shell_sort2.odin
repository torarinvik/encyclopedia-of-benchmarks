package shell_sort2

import "core:c"

@(export)
shell_sort2 :: proc "c" (values: [^]i64, length: c.size_t) {
	gaps := [8]int{701, 301, 132, 57, 23, 10, 4, 1}
	for gap_index := 0; gap_index < 8; gap_index += 1 {
		gap := gaps[gap_index]
		for index := gap; index < int(length); index += 1 {
			key := values[index]
			position := index
			for position >= gap && values[position-gap] > key {
				values[position] = values[position-gap]
				position -= gap
			}
			values[position] = key
		}
	}
}
