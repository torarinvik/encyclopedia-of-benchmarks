module hanging_line_largest_rectangle

const max_length = 64
const max_height = i64(1000000)
const invalid_result = i64(-9223372036854775807) - 1

@[export: 'hanging_line_largest_rectangle']
pub fn hanging_line_largest_rectangle(heights &i64, length usize) i64 {
	if length == 0 { return 0 }
	unsafe {
		if heights == nil || length > max_length { return invalid_result }
		for i in 0 .. int(length) {
			if heights[i] < 0 || heights[i] > max_height { return invalid_result }
		}

		mut left := [max_length]usize{}
		mut right := [max_length]usize{}
		for i in 0 .. int(length) {
			left[i] = usize(i)
			for left[i] > 0 && heights[i] <= heights[left[i] - 1] {
				left[i] = left[left[i] - 1]
			}
		}
		mut i := int(length) - 1
		for i >= 0 {
			right[i] = usize(i)
			for right[i] + 1 < length && heights[i] <= heights[right[i] + 1] {
				right[i] = right[right[i] + 1]
			}
			i--
		}

		mut best := i64(0)
		for j in 0 .. int(length) {
			width := i64(right[j] - left[j] + 1)
			area := heights[j] * width
			if area > best { best = area }
		}
		return best
	}
}
