module linear_regression_ols

const max_observations = 128
const invalid_result = -1.0e300

@[export: 'linear_regression_ols']
pub fn linear_regression_ols(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 5 || length > 257 || length % 2 == 0 { return invalid_result }
	unsafe {
		count := values[0]
		if count < 2 || count > max_observations || length != usize(1 + 2 * count) { return invalid_result }
		mut sum_x := 0.0
		mut sum_y := 0.0
		for index in 0 .. int(count) {
			x := values[1 + 2 * index]
			y := values[2 + 2 * index]
			if x < -1_000_000 || x > 1_000_000 || y < -1_000_000 || y > 1_000_000 { return invalid_result }
			sum_x += f64(x)
			sum_y += f64(y)
		}
		mean_x := sum_x / f64(count)
		mean_y := sum_y / f64(count)
		mut covariance := 0.0
		mut variance_x := 0.0
		mut variance_y := 0.0
		for index in 0 .. int(count) {
			dx := f64(values[1 + 2 * index]) - mean_x
			dy := f64(values[2 + 2 * index]) - mean_y
			covariance += dx * dy
			variance_x += dx * dx
			variance_y += dy * dy
		}
		if variance_x <= 1e-12 || variance_y <= 1e-12 { return invalid_result }
		return covariance / variance_x
	}
}
