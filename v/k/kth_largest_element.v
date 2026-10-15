module kth_largest_element

const max_length = 512

// Descending Lomuto quickselect with the final element as pivot.
@[export: 'kth_largest_element']
pub fn kth_largest_element(input &i64, length usize) i64 {
	if length < 2 || length > max_length + 1 { return -1 }
	count := length - 1
	k_value := unsafe { input[0] }
	if k_value < 1 || k_value > i64(count) { return -1 }
	mut values := [max_length]i32{}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	target := usize(k_value - 1)
	mut low := usize(0)
	mut high := count - 1
	for low <= high {
		pivot := values[high]
		mut boundary := low
		for scan in low .. high {
			if values[scan] >= pivot {
				temporary := values[boundary]
				values[boundary] = values[scan]
				values[scan] = temporary
				boundary++
			}
		}
		temporary := values[boundary]
		values[boundary] = values[high]
		values[high] = temporary
		if boundary == target { return i64(values[boundary]) }
		if boundary > target { high = boundary - 1 }
		else { low = boundary + 1 }
	}
	return -1
}
