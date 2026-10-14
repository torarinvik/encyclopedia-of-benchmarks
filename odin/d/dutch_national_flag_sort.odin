package dutch_national_flag_sort

import "core:c"

// Dutch national flag sort for values restricted to 0, 1, and 2.
@(export)
dutch_national_flag_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	low := c.size_t(0)
	middle := c.size_t(0)
	high := length
	for middle < high {
		if values[middle] == 0 {
			temporary := values[low]
			values[low] = values[middle]
			values[middle] = temporary
			low += 1
			middle += 1
		} else if values[middle] == 1 {
			middle += 1
		} else {
			high -= 1
			temporary := values[middle]
			values[middle] = values[high]
			values[high] = temporary
		}
	}
}
