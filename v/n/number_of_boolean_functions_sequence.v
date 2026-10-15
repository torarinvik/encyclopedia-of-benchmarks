@[export: 'number_of_boolean_functions_sequence']
pub fn number_of_boolean_functions_sequence(index i64) i64 {
	if index < 0 || index > 5 { return -1 }
	mut value := i64(2)
	for _ in 0 .. index {
		value *= value
	}
	return value
}
