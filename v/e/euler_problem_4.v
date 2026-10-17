module euler_problem_4

const max_parseable_input_length = 2

fn is_palindromic(value u32) bool {
	mut remaining := value
	mut reversed := u32(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

@[export: 'euler_problem_4']
pub fn euler_problem_4(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 3 || length != 1 { return -1 }
		digits := int(input[0])
		mut lower := u32(1)
		for digit in 1 .. digits { lower *= 10 }
		upper := lower * 10 - 1
		mut maximum := u32(0)
		mut left := lower
		for left <= upper {
			mut right := lower
			for right <= upper {
				product := left * right
				if product > maximum && is_palindromic(product) { maximum = product }
				right++
			}
			left++
		}
		return i64(maximum)
	}
}
