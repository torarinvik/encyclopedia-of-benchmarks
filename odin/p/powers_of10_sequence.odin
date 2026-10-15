package main

@(export, link_name="powers_of10_sequence")
powers_of10_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 18 do return -1
	value: i64 = 1
	for i: i64 = 0; i < index; i += 1 {
		value *= 10
	}
	return value
}

main :: proc() {}
