module almost_palindrome_checker

const max_length = 100000

fn is_palindrome_range(text &i64, left_start usize, right_start usize) bool {
	mut left := left_start
	mut right := right_start
	for left < right {
		if unsafe { text[left] != text[right - 1] } { return false }
		left++
		right--
	}
	return true
}

@[export: 'almost_palindrome_checker']
pub fn almost_palindrome_checker(text &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { text[index] }
		if value < 97 || value > 122 { return -1 }
	}
	mut left := usize(0)
	mut right := length
	for left < right {
		if unsafe { text[left] != text[right - 1] } {
			if is_palindrome_range(text, left + 1, right) || is_palindrome_range(text, left, right - 1) { return 1 }
			return 0
		}
		left++
		right--
	}
	return 1
}
