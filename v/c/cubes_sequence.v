@[export: 'cubes_sequence']
pub fn cubes_sequence(index i64) i64 {
	if index < 0 || index > 2097151 { return -1 }
	return index * index * index
}
