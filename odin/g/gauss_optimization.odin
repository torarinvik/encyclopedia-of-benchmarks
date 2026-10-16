package gauss_optimization
import "core:c"

objective :: proc "contextless" (x1, x2, target1, target2: f64) -> f64 {
	dx := x1 - target1
	dy := x2 - target2
	return -(dx*dx + dy*dy)
}

magnitude :: proc "contextless" (value: f64) -> f64 {
	if value < 0 do return -value
	return value
}

@(export)
gauss_optimization :: proc "c" (values: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(7) do return -1
	for i := 0; i < 7; i += 1 { if values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100 do return -1 }
	if (values[0] != 2.0 && values[0] != 3.0 && values[0] != 4.0) || values[1] < 0.25 || values[1] > 4.0 || values[2] < 1.0e-6 || values[2] > 2.0 do return -1
	for i := 3; i < 7; i += 1 { if values[i] < -8.0 || values[i] > 8.0 do return -1 }
	if output == nil || capacity < c.size_t(2) do return -2
	factor, step, epsilon := values[0], values[1], values[2]
	x1, x2, target1, target2 := values[3], values[4], values[5], values[6]
	error := 1.0
	iteration := 0
	for magnitude(error) > epsilon && iteration < 256 {
		current := objective(x1, x2, target1, target2)
		best := objective(x1, x2-step, target1, target2)
		choice := 0
		candidate := objective(x1, x2+step, target1, target2)
		if candidate > best { best = candidate; choice = 1 }
		candidate = objective(x1-step, x2, target1, target2)
		if candidate > best { best = candidate; choice = 2 }
		candidate = objective(x1+step, x2, target1, target2)
		if candidate > best { best = candidate; choice = 3 }
		error = best - current
		if choice == 0 { x2 -= step } else if choice == 1 { x2 += step } else if choice == 2 { x1 -= step } else { x1 += step }
		step /= factor
		iteration += 1
	}
	if magnitude(error) > epsilon do return -1
	output[0] = x1
	output[1] = x2
	return 2
}
