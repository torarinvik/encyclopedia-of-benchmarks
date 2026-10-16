module iqr_outlier_indices

const max_length = 62

fn type7_quantile(sorted &i64, count usize, probability f64) f64 {
	h := f64(count - 1) * probability + 1.0
	order := usize(h)
	fraction := h - f64(order)
	lower := order - 1
	if fraction == 0.0 || lower + 1 >= count { return f64(unsafe { sorted[lower] }) }
	return (1.0 - fraction) * f64(unsafe { sorted[lower] }) + fraction * f64(unsafe { sorted[lower + 1] })
}

@[export: 'iqr_outlier_indices']
pub fn iqr_outlier_indices(values voidptr, length usize) i64 {
	if length == usize(0) { return i64(-1) }
	if length > usize(max_length) { return i64(-1) }
	if unsafe { values == nil } { return i64(-1) }
	input_values := unsafe { &i64(values) }
	mut sorted := [max_length]i64{}
	for i in 0 .. length {
		value := unsafe { input_values[i] }
		if value < i64(-1000000) || value > i64(1000000) { return i64(-1) }
		mut position := i
		for position > 0 && sorted[position - 1] > value {
			sorted[position] = sorted[position - 1]
			position--
		}
		sorted[position] = value
	}
	q1 := type7_quantile(&sorted[0], length, 0.25)
	q3 := type7_quantile(&sorted[0], length, 0.75)
	iqr := q3 - q1
	lower_bound := q1 - 1.5 * iqr
	upper_bound := q3 + 1.5 * iqr
	mut mask := i64(0)
	for i in 0 .. length {
		value := f64(unsafe { input_values[i] })
		if value < lower_bound || value > upper_bound { mask |= i64(1) << i }
	}
	return mask
}
