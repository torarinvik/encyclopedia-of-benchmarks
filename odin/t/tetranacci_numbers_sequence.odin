package main

@(export, link_name="tetranacci_numbers_sequence")
tetranacci_numbers_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 68 do return -1
	a: i64 = 1
	b: i64 = 1
	c: i64 = 1
	d: i64 = 1
	if index <= 3 do return 1
	for i: i64 = 4; i <= index; i += 1 {
		next := a + b + c + d
		a = b
		b = c
		c = d
		d = next
	}
	return d
}

main :: proc() {}
