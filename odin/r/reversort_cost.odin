package reversort_cost

import "core:c"

@(export)
reversort_cost :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 { return -1 }
	working: [256]i64
	for index := 0; index < int(length); index += 1 {
		if values[index] < -2147483648 || values[index] > 2147483647 { return -1 }
		working[index] = values[index]
	}
	cost: i64 = 0
	for index := 0; index + 1 < int(length); index += 1 {
		minimum := index
		for probe := index + 1; probe < int(length); probe += 1 {
			if working[probe] < working[minimum] { minimum = probe }
		}
		left := index
		right := minimum
		for left < right {
			temporary := working[left]
			working[left] = working[right]
			working[right] = temporary
			left += 1
			right -= 1
		}
		cost += i64(minimum - index + 1)
	}
	return cost
}
