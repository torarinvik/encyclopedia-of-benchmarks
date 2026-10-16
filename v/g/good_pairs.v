module good_pairs

const max_n = 256
const value_limit = i64(1000000)

@[export: 'good_pairs']
pub fn good_pairs(packed &i64, length usize) i64 {
	if length == 0 || length > max_n + 1 { return -1 }
	n := unsafe { packed[0] }
	if n < 0 || n > max_n || length != usize(n) + 1 { return -1 }
	for index in 0 .. usize(n) {
		value := unsafe { packed[index + 1] }
		if value < -value_limit || value > value_limit { return -1 }
	}
	mut count := i64(0)
	for i in 0 .. usize(n) {
		for j in i + 1 .. usize(n) {
			if unsafe { packed[i + 1] == packed[j + 1] } { count++ }
		}
	}
	return count
}
