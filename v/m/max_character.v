module max_character

@[export: 'max_character']
pub fn max_character(values &i64, length usize) i64 {
	if length == 0 || length > 256 { return -1 }
	mut counts := [26]i64{}
	for i in 0 .. length {
		if values[i] < 97 || values[i] > 122 { return -1 }
		counts[int(values[i] - 97)]++
	}
	mut best := i64(0)
	mut code := i64(-1)
	mut tied := false
	for i in 0 .. 26 {
		if counts[i] > best {
			best = counts[i]
			code = 97 + i64(i)
			tied = false
		} else if counts[i] == best && best != 0 {
			tied = true
		}
	}
	if tied { return -1 }
	return code
}
