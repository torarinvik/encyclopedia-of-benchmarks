module median

// Return twice the statistical median using a local insertion-sorted copy.
@[export: 'median']
pub fn median(values &i64, length usize) i64 {
	if length == 0 || length > 1024 { return 0 }
	mut ordered := [1024]i64{}
	for index in 0 .. length {
		ordered[index] = unsafe { values[index] }
	}
	for index in 1 .. length {
		value := ordered[index]
		mut cursor := index
		for cursor > 0 && ordered[cursor - 1] > value {
			ordered[cursor] = ordered[cursor - 1]
			cursor--
		}
		ordered[cursor] = value
	}
	if length % 2 != 0 { return ordered[length / 2] * 2 }
	return ordered[length / 2 - 1] + ordered[length / 2]
}
