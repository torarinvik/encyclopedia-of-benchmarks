package kaprekar_constant

import "core:c"

kaprekar_step :: proc(number: i64) -> i64 {
	d0 := number / 1000
	d1 := (number / 100) % 10
	d2 := (number / 10) % 10
	d3 := number % 10
	temp := i64(0)

	if d0 > d1 { temp = d0; d0 = d1; d1 = temp }
	if d2 > d3 { temp = d2; d2 = d3; d3 = temp }
	if d0 > d2 { temp = d0; d0 = d2; d2 = temp }
	if d1 > d3 { temp = d1; d1 = d3; d3 = temp }
	if d1 > d2 { temp = d1; d1 = d2; d2 = temp }

	ascending := d0 * 1000 + d1 * 100 + d2 * 10 + d3
	descending := d3 * 1000 + d2 * 100 + d1 * 10 + d0
	return descending - ascending
}

@(export)
kaprekar_constant :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	number := values[0]
	max_iterations := values[1]
	if number < 0 || number > 9999 || max_iterations < 1 || max_iterations > 16 do return -1
	if number == 6174 do return 0

	current := number
	for iteration := i64(1); iteration <= max_iterations; iteration += 1 {
		current = kaprekar_step(current)
		if current == 6174 do return iteration
		if current == 0 do return -1
	}
	return -1
}
