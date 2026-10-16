module gaussian_negative_log_likelihood_loss

import math

const max_count = 256
const max_input_length = 1 + 3 * max_count
const invalid_result = -1.0e300

@[export: 'gaussian_negative_log_likelihood_loss']
pub fn gaussian_negative_log_likelihood_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 4 || length > max_input_length { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_count { return invalid_result }
		count := int(count_value)
		if length != 1 + 3 * count { return invalid_result }
		mut total := 0.0
		for i in 0 .. count {
			y_scaled := values[1 + i]
			mu_scaled := values[1 + count + i]
			variance_nano := values[1 + 2 * count + i]
			if y_scaled < -1_000_000 || y_scaled > 1_000_000 || mu_scaled < -1_000_000 || mu_scaled > 1_000_000 || variance_nano < 1 || variance_nano > 1_000_000_000 { return invalid_result }
			y := f64(y_scaled) / 1_000_000.0
			mu := f64(mu_scaled) / 1_000_000.0
			mut variance := f64(variance_nano) / 1_000_000_000.0
			if variance < 1e-6 { variance = 1e-6 }
			residual := y - mu
			loss_var := 0.5 * math.log(variance)
			loss_exp := 0.5 * ((residual * residual) / variance)
			total += loss_var + loss_exp
		}
		return total / f64(count)
	}
}
