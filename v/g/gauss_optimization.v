module gauss_optimization

fn objective(x1 f64, x2 f64, target1 f64, target2 f64) f64 {
	dx := x1 - target1
	dy := x2 - target2
	return -(dx * dx + dy * dy)
}

fn magnitude(value f64) f64 {
	if value < 0 { return -value }
	return value
}

@[export: 'gauss_optimization']
pub fn gauss_optimization(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 7 { return -1 }
		for i in 0 .. 7 {
			if values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100 { return -1 }
		}
		if (values[0] != 2.0 && values[0] != 3.0 && values[0] != 4.0) || values[1] < 0.25 || values[1] > 4.0 || values[2] < 1e-6 || values[2] > 2.0 { return -1 }
		for i in 3 .. 7 {
			if values[i] < -8.0 || values[i] > 8.0 { return -1 }
		}
		if isnil(output) || capacity < 2 { return -2 }
		factor := values[0]
		mut step := values[1]
		epsilon := values[2]
		mut x1 := values[3]
		mut x2 := values[4]
		target1 := values[5]
		target2 := values[6]
		mut error := 1.0
		mut iteration := 0
		for magnitude(error) > epsilon && iteration < 256 {
			current := objective(x1, x2, target1, target2)
			mut best := objective(x1, x2 - step, target1, target2)
			mut choice := 0
			mut candidate := objective(x1, x2 + step, target1, target2)
			if candidate > best { best = candidate; choice = 1 }
			candidate = objective(x1 - step, x2, target1, target2)
			if candidate > best { best = candidate; choice = 2 }
			candidate = objective(x1 + step, x2, target1, target2)
			if candidate > best { best = candidate; choice = 3 }
			error = best - current
			if choice == 0 { x2 -= step }
			else if choice == 1 { x2 += step }
			else if choice == 2 { x1 -= step }
			else { x1 += step }
			step /= factor
			iteration++
		}
		if magnitude(error) > epsilon { return -1 }
		output[0] = x1
		output[1] = x2
		return 2
	}
}
