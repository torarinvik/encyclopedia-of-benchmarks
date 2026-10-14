package pancake_sort

import "core:c"

flip_prefix :: proc(values: [^]i64, last_index: c.size_t) {
	first := c.size_t(0)
	last := last_index
	for first < last {
		temporary := values[first]
		values[first] = values[last]
		values[last] = temporary
		first += 1
		last -= 1
	}
}

// Pancake sort using prefix reversals for the shared sorting contract.
@(export)
pancake_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	for prefix := length; prefix > 1; prefix -= 1 {
		maximum := c.size_t(0)
		for probe := c.size_t(1); probe < prefix; probe += 1 {
			if values[probe] > values[maximum] {
				maximum = probe
			}
		}
		if maximum != prefix - 1 {
			flip_prefix(values, maximum)
			flip_prefix(values, prefix - 1)
		}
	}
}
