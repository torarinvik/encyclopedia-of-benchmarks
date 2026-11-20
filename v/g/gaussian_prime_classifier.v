module gaussian_prime_classifier

const max_coordinate = i64(10000)

fn gp_rational_prime(value i64) bool {
	if value < 2 { return false }
	if value % 2 == 0 { return value == 2 }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

@[export: 'gaussian_prime_classifier']
pub fn gaussian_prime_classifier(values &i64, length usize) i64 {
	if length < 1 || length > 3 || unsafe { values == nil } { return -1 }
	unsafe {
		if length != 2 { return -1 }
		real := values[0]
		imaginary := values[1]
		if real < -max_coordinate || real > max_coordinate ||
			imaginary < -max_coordinate || imaginary > max_coordinate { return -1 }
		if real == 0 && imaginary == 0 { return 0 }
		if real == 0 || imaginary == 0 {
			axis := if real == 0 { imaginary } else { real }
			rational := if axis < 0 { -axis } else { axis }
			if rational % 4 == 3 && gp_rational_prime(rational) { return 1 }
			return 0
		}
		norm := real * real + imaginary * imaginary
		if gp_rational_prime(norm) { return 1 }
		return 0
	}
}
