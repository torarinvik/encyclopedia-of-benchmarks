module palindromic_substrings

// Count all palindromic substrings by expanding around odd and even centers.
@[export: 'palindromic_substrings']
pub fn palindromic_substrings(values &i64, length usize) i64 {
	if length == 0 || length > 1000 { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 97 || value > 122 { return -1 }
	}

	mut count := i64(0)
	for center in 0 .. length {
		count++
		mut left := center
		mut right := center
		for left > 0 && right + 1 < length &&
			unsafe { values[left - 1] } == unsafe { values[right + 1] } {
			count++
			left--
			right++
		}

		left = center
		right = center + 1
		for right < length && unsafe { values[left] } == unsafe { values[right] } {
			count++
			if left == 0 || right + 1 == length { break }
			left--
			right++
		}
	}
	return count
}
