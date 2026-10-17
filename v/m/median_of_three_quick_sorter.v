module median_of_three_quick_sorter

fn median_of_three(a i64, b i64, c i64) i64 {
	if a <= b {
		if b <= c { return b }
		if a <= c { return c }
		return a
	}
	if b >= c { return b }
	if a >= c { return c }
	return a
}

fn partition_range(values &i64, left int, right int) int {
	unsafe {
		middle := left + (right - left) / 2
		pivot := median_of_three(values[left], values[middle], values[right])
		mut nleft := left
		mut nright := right
		for {
			for values[nleft] < pivot { nleft++ }
			for values[nright] > pivot { nright-- }
			if nleft >= nright { return nright }
			temporary := values[nleft]
			values[nleft] = values[nright]
			values[nright] = temporary
			nleft++
			nright--
		}
	}
}

fn sort_range(values &i64, left int, right int) {
	if left >= right { return }
	pivot := partition_range(values, left, right)
	sort_range(values, left, pivot)
	sort_range(values, pivot + 1, right)
}

@[export: 'median_of_three_quick_sorter']
pub fn median_of_three_quick_sorter(values &i64, length usize) {
	unsafe {
		if length > 1 { sort_range(values, 0, int(length) - 1) }
	}
}
