module squares_sequence

const max_index = i64(3037000499)

@[export: 'squares_sequence']
pub fn squares_sequence(index i64) i64 {
	if index < 0 || index > max_index { return -1 }
	return index * index
}
