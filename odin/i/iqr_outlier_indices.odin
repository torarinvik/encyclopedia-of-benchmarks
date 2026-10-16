package iqr_outlier_indices

import "core:c"

MAX_LENGTH :: 62
INVALID_RESULT :: i64(-1)

@(export)
iqr_outlier_indices :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
	sorted: [MAX_LENGTH]i64
	for i := c.size_t(0); i < length; i += 1 {
		value := values[i]
		if value < -1_000_000 || value > 1_000_000 do return INVALID_RESULT
		position := i
		for position > 0 && sorted[position - 1] > value {
			sorted[position] = sorted[position - 1]
			position -= 1
		}
		sorted[position] = value
	}
	q1_h := f64(length - 1) * 0.25 + 1.0
	q1_order := c.size_t(q1_h)
	q1_fraction := q1_h - f64(q1_order)
	q1_lower := q1_order - 1
	q1 := f64(sorted[q1_lower])
	if q1_fraction != 0 && q1_lower + 1 < length do q1 = (1.0 - q1_fraction) * f64(sorted[q1_lower]) + q1_fraction * f64(sorted[q1_lower + 1])
	q3_h := f64(length - 1) * 0.75 + 1.0
	q3_order := c.size_t(q3_h)
	q3_fraction := q3_h - f64(q3_order)
	q3_lower := q3_order - 1
	q3 := f64(sorted[q3_lower])
	if q3_fraction != 0 && q3_lower + 1 < length do q3 = (1.0 - q3_fraction) * f64(sorted[q3_lower]) + q3_fraction * f64(sorted[q3_lower + 1])
	iqr := q3 - q1
	lower_bound := q1 - 1.5 * iqr
	upper_bound := q3 + 1.5 * iqr
	mask := i64(0)
	for i := c.size_t(0); i < length; i += 1 {
		value := f64(values[i])
		if value < lower_bound || value > upper_bound do mask |= i64(1) << i
	}
	return mask
}
