module two_pointers_pair_count

const max_values = 256
const max_input_length = max_values + 2

fn sift_down(mut values &i64, root_start int, end_value int) {
	mut root := root_start
	for root < end_value / 2 {
		mut child := root * 2 + 1
		if child + 1 < end_value && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		unsafe {
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn heap_sort(mut values &i64, length int) {
	mut start := length / 2
	for start > 0 {
		start--
		sift_down(mut values, start, length)
	}
	mut ending := length
	for ending > 1 {
		ending--
		unsafe {
			temporary := values[0]
			values[0] = values[ending]
			values[ending] = temporary
		}
		sift_down(mut values, 0, ending)
	}
}

@[export: 'two_pointers_pair_count']
pub fn two_pointers_pair_count(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	target := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if count_value < 0 || count_value > max_values { return -1 }
	count := int(count_value)
	if length != usize(2 + count) || target < -2_000_000 || target > 2_000_000 { return -1 }

	mut values := [max_values]i64{init: 0}
	for index in 0 .. count {
		value := unsafe { input[2 + index] }
		if value < -1_000_000 || value > 1_000_000 { return -1 }
		values[index] = value
	}
	heap_sort(mut values[0], count)
  if count < 2 { return 0 }
	for index in 1 .. count {
		if values[index - 1] == values[index] { return -1 }
	}

	mut left := 0
	mut right := count - 1
	mut pairs := i64(0)
	for left < right {
		sum := values[left] + values[right]
		if sum < target {
			left++
		} else if sum > target {
			right--
		} else {
			pairs++
			left++
		}
	}
	return pairs
}

