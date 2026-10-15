module check_polygon

// Return one when positive side lengths can form a polygon, otherwise zero.
@[export: 'check_polygon']
pub fn check_polygon(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	_ = output
	_ = output_capacity
	if length < 3 || length > 256 || unsafe { values == nil } { return -1 }

	mut total := i64(0)
	mut largest := i64(0)
	for index in 0 .. length {
		value := values[index]
		if value < 1 || value > 1000000000 { return -1 }
		total += value
		if value > largest { largest = value }
	}
	return if largest < total - largest { i64(1) } else { i64(0) }
}
