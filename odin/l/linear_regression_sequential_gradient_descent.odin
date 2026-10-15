package linear_regression_sequential_gradient_descent

import "core:c"

MAX_EPOCHS :: 10000
INVALID_RESULT :: f64(-1.0e300)

@(export)
linear_regression_sequential_gradient_descent :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 7 || length > 131 || length % 2 == 0 do return INVALID_RESULT
	count := values[0]
	rate_microunits := values[1]
	epochs := values[2]
	if count < 2 || count > 64 || length != c.size_t(3 + 2 * count) || rate_microunits < 1 || rate_microunits > 1000 || epochs < 1 || epochs > MAX_EPOCHS do return INVALID_RESULT
	for index := c.size_t(0); index < c.size_t(count); index += 1 {
		x := values[3 + 2 * index]
		y := values[4 + 2 * index]
		if x < -10 || x > 10 || y < -100 || y > 100 do return INVALID_RESULT
	}

	alpha := f64(rate_microunits) / 1_000_000.0
	scale := alpha / f64(count)
	slope := f64(0)
	intercept := f64(0)
	cost := f64(0)
	for epoch := i64(0); epoch < epochs; epoch += 1 {
		slope_gradient := f64(0)
		for index := c.size_t(0); index < c.size_t(count); index += 1 {
			x := f64(values[3 + 2 * index])
			y := f64(values[4 + 2 * index])
			slope_gradient += (slope * x + intercept - y) * x
		}
		slope -= scale * slope_gradient

		intercept_gradient := f64(0)
		for index := c.size_t(0); index < c.size_t(count); index += 1 {
			x := f64(values[3 + 2 * index])
			y := f64(values[4 + 2 * index])
			intercept_gradient += slope * x + intercept - y
		}
		intercept -= scale * intercept_gradient

		cost = 0
		for index := c.size_t(0); index < c.size_t(count); index += 1 {
			x := f64(values[3 + 2 * index])
			y := f64(values[4 + 2 * index])
			error := slope * x + intercept - y
			cost += error * error
		}
		cost /= 2.0 * f64(count)
	}
	return cost
}
