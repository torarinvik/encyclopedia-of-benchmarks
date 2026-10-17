module linear_search_thread

const max_count = 64
const max_input_length = 69
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)

@[export: 'linear_search_thread']
pub fn linear_search_thread(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	count_arg := unsafe { input[0] }
	left := unsafe { input[1] }
	right := unsafe { input[2] }
	target := unsafe { input[3] }
	if count_arg < 1 || count_arg > max_count || length != usize(count_arg) + 4 { return -1 }
	if left < 0 || left > right || right > count_arg || target < i32_min || target > i32_max {
		return -1
	}
	count := usize(count_arg)
	for index := usize(0); index < count; index++ {
		value := unsafe { input[index + 4] }
		if value < i32_min || value > i32_max { return -1 }
	}
	for index := usize(left); index < usize(right); index++ {
		if unsafe { input[index + 4] } == target { return 1 }
	}
	return 0
}
