package shell_sort

import "core:c"

// Shell sort with a halving gap sequence for the shared contract.
@(export)
shell_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	gap := length / 2
	for gap > 0 {
		for index := gap; index < length; index += 1 {
			key := values[index]
			position := index
			for position >= gap && values[position - gap] > key {
				values[position] = values[position - gap]
				position -= gap
			}
			values[position] = key
		}
		gap /= 2
	}
}
