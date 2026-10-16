package gaussian_negative_log_likelihood_loss

import "core:c"

MAX_COUNT :: 256
MAX_INPUT_LENGTH :: 1 + 3 * MAX_COUNT
INVALID_RESULT :: f64 = -1.0e300

@(export)
gaussian_negative_log_likelihood_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 4 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	count_value := values[0]
	if count_value < 1 || count_value > MAX_COUNT do return INVALID_RESULT
	count := int(count_value)
	if length != c.size_t(1 + 3 * count) do return INVALID_RESULT
	total := f64(0.0)
	for i := 0; i < count; i += 1 {
		y_scaled := values[1 + i]
		mu_scaled := values[1 + count + i]
		variance_nano := values[1 + 2 * count + i]
		if y_scaled < -1_000_000 || y_scaled > 1_000_000 || mu_scaled < -1_000_000 || mu_scaled > 1_000_000 || variance_nano < 1 || variance_nano > 1_000_000_000 do return INVALID_RESULT
		y := f64(y_scaled) / 1_000_000.0
		mu := f64(mu_scaled) / 1_000_000.0
		variance := f64(variance_nano) / 1_000_000_000.0
		if variance < 1e-6 do variance = 1e-6
		residual := y - mu
		loss_var := 0.5 * math.log_f64(variance)
		loss_exp := 0.5 * ((residual * residual) / variance)
		total += loss_var + loss_exp
	}
	return total / f64(count)
}
