package gaussian_legendre

import "core:c"

INVALID_RESULT :: -1.0e300

@(export)
gaussian_legendre :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 7 do return INVALID_RESULT
	if values[0] < 1 || values[0] > 5 || values[1] < -5000 || values[1] > 5000 do return INVALID_RESULT
	if values[2] < -5000 || values[2] > 5000 do return INVALID_RESULT
	for index := 3; index < 7; index += 1 {
		if values[index] < -10000 || values[index] > 10000 do return INVALID_RESULT
	}

	order := int(values[0])
	nodes: [5]f64
	weights: [5]f64
	switch order {
	case 1:
		nodes[0] = 0; weights[0] = 2
	case 2:
		nodes[0] = -0.5773502692; nodes[1] = 0.5773502692
		weights[0] = 1; weights[1] = 1
	case 3:
		nodes[0] = -0.7745966692; nodes[1] = 0; nodes[2] = 0.7745966692
		weights[0] = 0.5555555556; weights[1] = 0.8888888889; weights[2] = 0.5555555556
	case 4:
		nodes[0] = -0.8611363116; nodes[1] = -0.3399810436
		nodes[2] = 0.3399810436; nodes[3] = 0.8611363116
		weights[0] = 0.3478548451; weights[1] = 0.6521451549
		weights[2] = 0.6521451549; weights[3] = 0.3478548451
	case 5:
		nodes[0] = -0.9061798459; nodes[1] = -0.5384693101; nodes[2] = 0
		nodes[3] = 0.5384693101; nodes[4] = 0.9061798459
		weights[0] = 0.2369268851; weights[1] = 0.4786286705
		weights[2] = 0.5688888889; weights[3] = 0.4786286705; weights[4] = 0.2369268851
	}
	a, b := f64(values[1])/1000, f64(values[2])/1000
	c0, c1 := f64(values[3])/1000, f64(values[4])/1000
	c2, c3 := f64(values[5])/1000, f64(values[6])/1000
	weighted_sum: f64 = 0
	for index := 0; index < order; index += 1 {
		x := (b + a)/2 + (b - a)*nodes[index]/2
		x2 := x*x
		x3 := x2*x
		function_value := c0 + c1*x + c2*x2 + c3*x3
		weighted_sum += weights[index] * function_value
	}
	return weighted_sum * (b - a) / 2
}
