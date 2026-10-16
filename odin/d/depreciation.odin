package depreciation

import "core:c"

MAX_YEARS :: 16
MAX_VALUE_MICRO :: i64(1_000_000_000_000)
MAX_RATE_PPM :: i64(1_000_000)
MAX_UNITS :: i64(1_000_000_000)

write_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

min_f64 :: proc "contextless" (left, right: f64) -> f64 {
	if left < right do return left
	return right
}

max_f64 :: proc "contextless" (left, right: f64) -> f64 {
	if left > right do return left
	return right
}

@(export)
depreciation :: proc "c" (values: [^]i64, length: c.size_t,
										 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > MAX_YEARS + 4 do return -1
	method := values[0]
	years := 0
	purchase_scaled := i64(0)
	residual_scaled := i64(0)
	rate := 0.0
	if method == 0 || method == 3 || method == 4 {
		if length != 4 || values[1] < 1 || values[1] > MAX_YEARS do return -1
		years = int(values[1])
		purchase_scaled = values[2]; residual_scaled = values[3]
	} else if method == 1 {
		if length != 5 || values[1] < 1 || values[1] > MAX_YEARS || values[4] < 1 || values[4] > MAX_RATE_PPM do return -1
		years = int(values[1])
		purchase_scaled = values[2]; residual_scaled = values[3]
		rate = f64(values[4]) / 1_000_000.0
	} else if method == 2 {
		if length < 5 do return -1
		years = int(length) - 4
		if years > MAX_YEARS || values[3] < 1 || values[3] > MAX_UNITS do return -1
		purchase_scaled = values[1]; residual_scaled = values[2]
		unit_sum := 0.0
		for i := 0; i < years; i += 1 {
			if values[4 + i] < -MAX_UNITS || values[4 + i] > MAX_UNITS do return -1
			unit_sum += f64(values[4 + i])
		}
		delta := unit_sum - f64(values[3])
		if delta < 0 do delta = -delta
		if delta > 1.0e-6 * f64(values[3]) do return -1
	} else do return -1

	if purchase_scaled < 0 || purchase_scaled > MAX_VALUE_MICRO || residual_scaled < -MAX_VALUE_MICRO || residual_scaled > purchase_scaled do return -1
	purchase := f64(purchase_scaled) / 1_000_000.0
	residual := f64(residual_scaled) / 1_000_000.0
	depreciable_cost := purchase - residual
	schedule: [MAX_YEARS]f64 = {}

	if method == 0 {
		annual := depreciable_cost / f64(years)
		accumulated := 0.0
		for period := 0; period < years; period += 1 {
			if period == years - 1 do schedule[period] = depreciable_cost - accumulated
			else { accumulated += annual; schedule[period] = annual }
		}
	} else if method == 1 {
		book_value := purchase
		for period := 0; period < years; period += 1 {
			if period == years - 1 do schedule[period] = book_value - residual
			else {
				expense := min_f64(book_value * rate, book_value - residual)
				schedule[period] = expense
				book_value -= expense
			}
		}
	} else if method == 2 {
		per_unit := depreciable_cost / f64(values[3])
		accumulated := 0.0
		for period := 0; period < years; period += 1 {
			if period == years - 1 do schedule[period] = depreciable_cost - accumulated
			else {
				expense := f64(values[4 + period]) * per_unit
				accumulated += expense
				schedule[period] = expense
			}
		}
	} else if method == 3 {
		syd := f64(years) * (f64(years) + 1.0) / 2.0
		accumulated := 0.0
		for period := 1; period <= years; period += 1 {
			if period == years do schedule[period - 1] = depreciable_cost - accumulated
			else {
				expense := (f64(years - period + 1) / syd) * depreciable_cost
				accumulated += expense
				schedule[period - 1] = expense
			}
		}
	} else {
		ddb_rate := 2.0 / f64(years)
		book_value := purchase
		accumulated := 0.0
		for period := 1; period <= years; period += 1 {
			remaining := f64(years - period + 1)
			ddb := max_f64(book_value * ddb_rate, 0.0)
			straight_line := max_f64((book_value - residual) / remaining, 0.0)
			expense := min_f64(max_f64(ddb, straight_line), book_value - residual)
			if period == years do schedule[period - 1] = depreciable_cost - accumulated
			else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense }
		}
	}

	output_bytes := years * 8
	if output == nil || output_bytes > int(output_capacity) do return -2
	for i := 0; i < years; i += 1 do write_f64_le(output, i * 8, schedule[i])
	return i64(output_bytes)
}
