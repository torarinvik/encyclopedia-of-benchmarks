module kaprekar_constant

fn kaprekar_step(number i64) i64 {
	mut d0 := number / 1000
	mut d1 := (number / 100) % 10
	mut d2 := (number / 10) % 10
	mut d3 := number % 10
	mut temp := i64(0)

	if d0 > d1 { temp = d0; d0 = d1; d1 = temp }
	if d2 > d3 { temp = d2; d2 = d3; d3 = temp }
	if d0 > d2 { temp = d0; d0 = d2; d2 = temp }
	if d1 > d3 { temp = d1; d1 = d3; d3 = temp }
	if d1 > d2 { temp = d1; d1 = d2; d2 = temp }

	ascending := d0 * 1000 + d1 * 100 + d2 * 10 + d3
	descending := d3 * 1000 + d2 * 100 + d1 * 10 + d0
	return descending - ascending
}

@[export: 'kaprekar_constant']
pub fn kaprekar_constant(values &i64, length usize) i64 {
	if length != 2 || unsafe { values == nil } { return -1 }
	unsafe {
		number := values[0]
		max_iterations := values[1]
		if number < 0 || number > 9999 || max_iterations < 1 || max_iterations > 16 { return -1 }
		if number == 6174 { return 0 }

		mut current := number
		for iteration in i64(1) .. max_iterations + i64(1) {
			current = kaprekar_step(current)
			if current == 6174 { return iteration }
			if current == 0 { return -1 }
		}
	}
	return -1
}
