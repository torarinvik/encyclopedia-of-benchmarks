module linear_regression_sequential_gradient_descent

const max_epochs = 10000
const invalid_result = -1.0e300

@[export: 'linear_regression_sequential_gradient_descent']
pub fn linear_regression_sequential_gradient_descent(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 7 || length > 131 || length % 2 == 0 { return invalid_result }
	unsafe {
		count := values[0]
		rate_microunits := values[1]
		epochs := values[2]
		if count < 2 || count > 64 || length != usize(3 + 2 * count) || rate_microunits < 1 || rate_microunits > 1000 || epochs < 1 || epochs > max_epochs { return invalid_result }
		for index in 0 .. int(count) {
			x := values[3 + 2 * index]
			y := values[4 + 2 * index]
			if x < -10 || x > 10 || y < -100 || y > 100 { return invalid_result }
		}
		alpha := f64(rate_microunits) / 1_000_000.0
		scale := alpha / f64(count)
		mut slope := 0.0
		mut intercept := 0.0
		mut cost := 0.0
		for _ in 0 .. int(epochs) {
			mut slope_gradient := 0.0
			for index in 0 .. int(count) {
				x := f64(values[3 + 2 * index])
				y := f64(values[4 + 2 * index])
				slope_gradient += (slope * x + intercept - y) * x
			}
			slope -= scale * slope_gradient

			mut intercept_gradient := 0.0
			for index in 0 .. int(count) {
				x := f64(values[3 + 2 * index])
				y := f64(values[4 + 2 * index])
				intercept_gradient += slope * x + intercept - y
			}
			intercept -= scale * intercept_gradient

			cost = 0.0
			for index in 0 .. int(count) {
				x := f64(values[3 + 2 * index])
				y := f64(values[4 + 2 * index])
				error := slope * x + intercept - y
				cost += error * error
			}
			cost /= 2.0 * f64(count)
		}
		return cost
	}
}
