module reversort_cost

@[export: 'reversort_cost']
pub fn reversort_cost(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	mut working := [256]i64{}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		working[index] = value
	}
	if length < 2 { return 0 }
	mut cost := i64(0)
	for index in 0 .. int(length) - 1 {
		mut minimum := index
		for probe in index + 1 .. int(length) {
			if working[probe] < working[minimum] { minimum = probe }
		}
		mut left := index
		mut right := minimum
		for left < right {
			temporary := working[left]
			working[left] = working[right]
			working[right] = temporary
			left++
			right--
		}
		cost += i64(minimum - index + 1)
	}
	return cost
}
