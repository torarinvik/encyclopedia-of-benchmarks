module largest_rectangle_histogram

@[export: 'largest_rectangle_histogram']
pub fn largest_rectangle_histogram(heights &i64, length usize) i64 {
	if length == 0 { return 0 }
	unsafe {
		if heights == nil || length > 64 { return i64(-9223372036854775807) - 1 }
		for index in 0 .. int(length) {
			if heights[index] < 0 || heights[index] > 1000000 { return i64(-9223372036854775807) - 1 }
		}

		mut stack := [64]usize{}
		mut top := usize(0)
		mut best := i64(0)
		for index in 0 .. int(length) {
			for top > 0 && heights[stack[top - 1]] > heights[index] {
				top--
				bar := stack[top]
				left := if top == 0 { usize(0) } else { stack[top - 1] + 1 }
				best = max(best, heights[bar] * i64(usize(index) - left))
			}
			stack[top] = usize(index)
			top++
		}
		for top > 0 {
			top--
			bar := stack[top]
			left := if top == 0 { usize(0) } else { stack[top - 1] + 1 }
			best = max(best, heights[bar] * i64(length - left))
		}
		return best
	}
}
