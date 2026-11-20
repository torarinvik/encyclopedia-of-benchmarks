module jsort

fn sift_down_min(mut values &i64, root_value usize, end usize) {
	mut root := root_value
	for root < end / 2 {
		mut child := root * 2 + 1
		unsafe {
			if child + 1 < end && values[child + 1] < values[child] {
				child++
			}
			if values[root] <= values[child] {
				break
			}
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn sift_down_max(mut values &i64, root_value usize, end usize) {
	mut root := root_value
	for root < end / 2 {
		mut child := root * 2 + 1
		unsafe {
			if child + 1 < end && values[child + 1] > values[child] {
				child++
			}
			if values[root] >= values[child] {
				break
			}
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn reverse_values(mut values &i64, length usize) {
	for left in 0 .. length / 2 {
		right := length - 1 - left
		unsafe {
			temporary := values[left]
			values[left] = values[right]
			values[right] = temporary
		}
	}
}

@[export: 'jsort']
pub fn jsort(mut values &i64, length usize) {
	if values == nil || length < 2 {
		return
	}
	mut start := length / 2
	for start > 0 {
		start--
		sift_down_min(mut values, start, length)
	}
	reverse_values(mut values, length)
	start = length / 2
	for start > 0 {
		start--
		sift_down_max(mut values, start, length)
	}
	reverse_values(mut values, length)

	for index in 1 .. length {
		key := unsafe { values[index] }
		mut position := index
		for position > 0 {
			previous := unsafe { values[position - 1] }
			if previous <= key {
				break
			}
			unsafe {
				values[position] = previous
			}
			position--
		}
		unsafe {
			values[position] = key
		}
	}
}
