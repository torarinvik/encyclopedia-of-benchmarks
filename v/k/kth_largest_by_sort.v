module kth_largest_by_sort

const max_length = 512

fn sift_down(values &i32, root_start int, end int) {
	mut root := root_start
	for root < end / 2 {
		mut child := root * 2 + 1
		if child + 1 < end && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		unsafe {
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

// Sort a local copy with portable heapsort, then index from the end.
@[export: 'kth_largest_by_sort']
pub fn kth_largest_by_sort(input &i64, length usize) i64 {
	if length < 2 || length > max_length + 1 { return -1 }
	n := int(length) - 1
	k_value := unsafe { input[0] }
	if k_value < 1 || k_value > i64(n) { return -1 }
	mut values := [max_length]i32{}
	for index in 0 .. n {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	for start := n / 2; start > 0; start-- {
		sift_down(&values[0], start - 1, n)
	}
	mut end := n
	for end > 1 {
		temporary := values[0]
		values[0] = values[end - 1]
		values[end - 1] = temporary
		end--
		sift_down(&values[0], 0, end)
	}
	return i64(values[n - int(k_value)])
}
