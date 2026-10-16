module mode

@[export: 'mode']
pub fn mode(values &i64, length usize) i64 {
	if length == 0 || length > 4096 { return -1 }
	mut counts := [256]int{}
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 255 { return -1 }
		counts[int(value)]++
	}
	mut maximum := 0
	mut result := i64(-1)
	mut unique := true
	for value in 0 .. 256 {
		if counts[value] > maximum {
			maximum = counts[value]
			result = i64(value)
			unique = true
		} else if counts[value] != 0 && counts[value] == maximum {
			unique = false
		}
	}
	return if unique { result } else { -1 }
}
