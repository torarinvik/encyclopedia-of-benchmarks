package main

// Return a term from the bounded powers-of-two sequence.
@(export, link_name="powers_of2_sequence")
powers_of2_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 62 do return -1
	value: i64 = 1
	for step: i64 = 0; step < index; step += 1 {
		value *= 2
	}
	return value
}

main :: proc() {}
