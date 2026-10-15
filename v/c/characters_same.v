module characters_same

@[export: 'characters_same']
pub fn characters_same(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	for index in 0 .. length {
		if values[index] < 0 || values[index] > 127 { return -1 }
	}
	if length == 0 { return 1 }
	first := values[0]
	for index in 1 .. length {
		if values[index] != first { return 0 }
	}
	return 1
}
