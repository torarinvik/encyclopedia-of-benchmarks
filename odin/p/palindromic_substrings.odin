package palindromic_substrings

import "core:c"

// Count all palindromic substrings by expanding around odd and even centers.
@(export)
palindromic_substrings :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 1000 || values == nil do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if values[index] < 97 || values[index] > 122 do return -1
	}

	count := i64(0)
	for center: c.size_t = 0; center < length; center += 1 {
		count += 1
		left := center
		right := center
		for left > 0 && right + 1 < length && values[left - 1] == values[right + 1] {
			count += 1
			left -= 1
			right += 1
		}

		left = center
		right = center + 1
		for right < length && values[left] == values[right] {
			count += 1
			if left == 0 || right + 1 == length do break
			left -= 1
			right += 1
		}
	}
	return count
}
