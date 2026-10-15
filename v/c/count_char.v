module count_char

@[export: 'count_char']
pub fn count_char(values &i64, length usize) i64 {
	if length > 4096 || (length > 0 && isnil(values)) {
		return -1
	}
	mut count := i64(0)
	for i in 0 .. length {
		code := unsafe { values[i] }
		if code < 0 || code > 127 {
			return -1
		}
		if code != 9 && code != 10 && code != 11 && code != 12 && code != 13 && code != 32 {
			count++
		}
	}
	return count
}
