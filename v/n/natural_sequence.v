@[export: 'natural_sequence']
pub fn natural_sequence(index i64) i64 {
	if index < 0 || index == i64(9223372036854775807) { return -1 }
	return index + 1
}
