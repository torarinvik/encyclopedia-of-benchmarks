package average_mode

import "core:c"

@(export)
average_mode :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > 64 do return -1
	for i in 0..<length {
		if values[i] < 0 || values[i] > 1000 do return -1
	}

	mode := i64(-1)
	maximum_count := c.size_t(0)
	mut tied := false
	for i in 0..<length {
		mut seen := false
		for before in 0..<i {
			if values[before] == values[i] { seen = true; break }
		}
		if seen do continue

		mut count := c.size_t(0)
		for j in 0..<length {
			if values[j] == values[i] { count += 1 }
		}
		if count > maximum_count {
			maximum_count = count
			mode = values[i]
			tied = false
		} else if count == maximum_count {
			tied = true
		}
	}
	if tied do return -1
	return mode
}
