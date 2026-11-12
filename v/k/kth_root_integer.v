module kth_root_integer

fn power_at_most(base i64, exponent_input i64, limit i64) bool {
	if base == 0 { return true }
	mut product := i64(1)
	mut exponent := exponent_input
	for exponent > 0 {
		if product > limit / base { return false }
		product *= base
		exponent -= 1
	}
	return true
}

@[export: 'kth_root_integer']
pub fn kth_root_integer(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	number := unsafe { input[0] }
	degree := unsafe { input[1] }
	if number < 0 || degree < 1 || degree > 64 { return -1 }

	mut low := i64(0)
	mut high := number
	for low < high {
		difference := high - low
		candidate := low + difference / 2 + difference % 2
		if power_at_most(candidate, degree, number) { low = candidate } else { high = candidate - 1 }
	}
	return low
}
