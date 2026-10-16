module gaussian_legendre

const invalid_result = -1.0e300

// Bounded Gauss-Legendre quadrature using the pinned Fortran tables.
@[export: 'gaussian_legendre']
pub fn gaussian_legendre(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 7 { return invalid_result }
	order_value := unsafe { values[0] }
	if order_value < 1 || order_value > 5 { return invalid_result }
	if unsafe { values[1] < -5000 || values[1] > 5000 || values[2] < -5000 || values[2] > 5000 } {
		return invalid_result
	}
	unsafe {
		for index in 3 .. 7 {
			if values[index] < -10000 || values[index] > 10000 { return invalid_result }
		}
	}
	order := int(order_value)
	mut nodes := [5]f64{}
	mut weights := [5]f64{}
	match order {
		1 { nodes[0] = 0.0; weights[0] = 2.0 }
		2 {
			nodes[0] = -0.5773502692; nodes[1] = 0.5773502692
			weights[0] = 1.0; weights[1] = 1.0
		}
		3 {
			nodes[0] = -0.7745966692; nodes[1] = 0.0; nodes[2] = 0.7745966692
			weights[0] = 0.5555555556; weights[1] = 0.8888888889; weights[2] = 0.5555555556
		}
		4 {
			nodes[0] = -0.8611363116; nodes[1] = -0.3399810436
			nodes[2] = 0.3399810436; nodes[3] = 0.8611363116
			weights[0] = 0.3478548451; weights[1] = 0.6521451549
			weights[2] = 0.6521451549; weights[3] = 0.3478548451
		}
		else {
			nodes[0] = -0.9061798459; nodes[1] = -0.5384693101; nodes[2] = 0.0
			nodes[3] = 0.5384693101; nodes[4] = 0.9061798459
			weights[0] = 0.2369268851; weights[1] = 0.4786286705
			weights[2] = 0.5688888889; weights[3] = 0.4786286705; weights[4] = 0.2369268851
		}
	}
	a := f64(unsafe { values[1] }) / 1000.0
	b := f64(unsafe { values[2] }) / 1000.0
	c0 := f64(unsafe { values[3] }) / 1000.0
	c1 := f64(unsafe { values[4] }) / 1000.0
	c2 := f64(unsafe { values[5] }) / 1000.0
	c3 := f64(unsafe { values[6] }) / 1000.0
	mut weighted_sum := 0.0
	for index in 0 .. order {
		x := (b + a) / 2.0 + (b - a) * nodes[index] / 2.0
		x2 := x * x
		x3 := x2 * x
		function_value := c0 + c1 * x + c2 * x2 + c3 * x3
		weighted_sum += weights[index] * function_value
	}
	return weighted_sum * (b - a) / 2.0
}
