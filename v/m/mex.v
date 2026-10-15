module mex

const max_values = 100000

fn sift_down(values &i64, root_start int, end int) {
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

fn heap_sort(values &i64, length int) {
	for start := length / 2; start > 0; start-- {
		sift_down(values, start - 1, length)
	}
	mut end := length
	for end > 1 {
		unsafe {
			temporary := values[0]
			values[0] = values[end - 1]
			values[end - 1] = temporary
		}
		end--
		sift_down(values, 0, end)
	}
}

@[export: 'mex']
pub fn mex(input &i64, length usize) i64 {
	if length < 1 || length > max_values + 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_values || length != usize(count_value) + 1 { return -1 }
	count := int(count_value)
	mut values := [max_values]i64{}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = value
	}
	heap_sort(&values[0], count)
	mut candidate := i64(0)
	for index in 0 .. count {
		if values[index] == candidate { candidate++ }
	}
	return candidate
}
