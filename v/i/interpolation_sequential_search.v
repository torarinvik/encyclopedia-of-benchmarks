module interpolation_sequential_search

const max_n = 64
const min_value = i64(-1000000)
const max_value = i64(1000000)

@[export: 'interpolation_sequential_search']
pub fn interpolation_sequential_search(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_n + 3 { return -1 }
	count_value := unsafe { input[0] }
	target := unsafe { input[1] }
	if count_value < 0 || count_value > max_n || length != usize(count_value + 2) { return -1 }
	if target < min_value || target > max_value { return -1 }
	count := int(count_value)
	for i in 0 .. count {
		value := unsafe { input[i + 2] }
		if value < min_value || value > max_value { return -1 }
		if i > 0 {
			previous := unsafe { input[i + 1] }
			if previous >= value { return -1 }
		}
	}
	if count == 0 { return -1 }
	first := unsafe { input[2] }
	last := unsafe { input[count + 1] }
	if target < first || target > last { return -1 }
	if count == 1 {
		if first == target { return 0 }
		return -1
	}

	position := int((target - first) * i64(count - 1) / (last - first))
	estimated := unsafe { input[position + 2] }
	if estimated == target { return i64(position) }
	if estimated < target {
		for i in position + 1 .. count {
			value := unsafe { input[i + 2] }
			if value >= target {
				if value == target { return i64(i) }
				return -1
			}
		}
	} else {
		mut i := position
		for i > 0 {
			i--
			value := unsafe { input[i + 2] }
			if value <= target {
				if value == target { return i64(i) }
				return -1
			}
		}
	}
	return -1
}
