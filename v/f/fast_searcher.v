module fast_searcher

const max_array_length = 64
const max_input_length = 67

fn search_segment(input &i64, begin int, length int, target i64, offset int) i64 {
	unsafe {
		if length == 0 { return -1 }
		first := input[begin]
		last := input[begin + length - 1]
		if target < first || target > last { return -1 }
		if first == last { return if target == first { i64(offset) } else { i64(-1) } }

		interpolation := int(target - first) * (length - 1) / int(last - first)
		midpoint := length / 2
		left := min(interpolation, midpoint)
		right := max(interpolation, midpoint)
		mut from := 0
		mut to := 0
		if target < input[begin + left] {
			if left == 0 { return -1 }
			from = 0
			to = left - 1
		} else if target < input[begin + right] {
			from = left
			to = right - 1
		} else {
			from = right
			to = length - 1
		}
		if to < from { return -1 }
		return search_segment(input, begin + from, to - from + 1, target, offset + from)
	}
}

@[export: 'fast_searcher']
pub fn fast_searcher(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -2 }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > max_array_length { return -2 }
		count := int(count_value)
		if length != usize(count + 2) { return -2 }
		for index in 0 .. count {
			value := input[1 + index]
			if value < -1000 || value > 1000 { return -2 }
			if index > 0 && input[index] >= value { return -2 }
		}
		target := input[int(length) - 1]
		if target < -1000 || target > 1000 { return -2 }
		return search_segment(input, 1, count, target, 0)
	}
}
