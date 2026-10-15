module chebyshev_distance

// Return the greatest absolute coordinate difference from packed points.
@[export: 'chebyshev_distance']
pub fn chebyshev_distance(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	dimension_value := unsafe { values[0] }
	if dimension_value < 1 || dimension_value > 128 { return -1 }
	dimension := usize(dimension_value)
	if length != 1 + 2 * dimension { return -1 }
	mut maximum := i64(0)
	for i in 0 .. dimension {
		a := unsafe { values[1 + i] }
		b := unsafe { values[1 + dimension + i] }
		if a < -1_000_000_000 || a > 1_000_000_000 || b < -1_000_000_000 || b > 1_000_000_000 { return -1 }
		mut difference := a - b
		if difference < 0 { difference = -difference }
		if difference > maximum { maximum = difference }
	}
	return maximum
}
