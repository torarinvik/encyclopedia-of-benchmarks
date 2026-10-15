package main

@(export, link_name="number_of_boolean_functions_sequence")
number_of_boolean_functions_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 5 do return -1
	value: i64 = 2
	for i: i64 = 0; i < index; i += 1 {
		value *= value
	}
	return value
}

main :: proc() {}
