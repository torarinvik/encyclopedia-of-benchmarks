module main

import math

const max_years = 16
const max_value_micro = i64(1_000_000_000_000)
const max_rate_ppm = i64(1_000_000)
const max_units = i64(1_000_000_000)

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn min_f64(left f64, right f64) f64 {
	if left < right { return left }
	return right
}

fn max_f64(left f64, right f64) f64 {
	if left > right { return left }
	return right
}

@[export: 'depreciation']
pub fn depreciation(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_years + 4 { return -1 }
		method := input[0]
		mut years := 0
		mut purchase_scaled := i64(0)
		mut residual_scaled := i64(0)
		mut rate := 0.0
		if method == 0 || method == 3 || method == 4 {
			if length != 4 || input[1] < 1 || input[1] > max_years { return -1 }
			years = int(input[1])
			purchase_scaled = input[2]; residual_scaled = input[3]
		} else if method == 1 {
			if length != 5 || input[1] < 1 || input[1] > max_years || input[4] < 1 || input[4] > max_rate_ppm { return -1 }
			years = int(input[1])
			purchase_scaled = input[2]; residual_scaled = input[3]
			rate = f64(input[4]) / 1_000_000.0
		} else if method == 2 {
			if length < 5 { return -1 }
			years = int(length) - 4
			if years > max_years || input[3] < 1 || input[3] > max_units { return -1 }
			purchase_scaled = input[1]; residual_scaled = input[2]
			mut unit_sum := 0.0
			for index in 0 .. years {
				if input[4 + index] < -max_units || input[4 + index] > max_units { return -1 }
				unit_sum += f64(input[4 + index])
			}
			delta := unit_sum - f64(input[3])
			if math.abs(delta) > 1.0e-6 * f64(input[3]) { return -1 }
		} else { return -1 }

		if purchase_scaled < 0 || purchase_scaled > max_value_micro || residual_scaled < -max_value_micro || residual_scaled > purchase_scaled { return -1 }
		purchase := f64(purchase_scaled) / 1_000_000.0
		residual := f64(residual_scaled) / 1_000_000.0
		depreciable_cost := purchase - residual
		mut schedule := [16]f64{}

		if method == 0 {
			annual := depreciable_cost / f64(years)
			mut accumulated := 0.0
			for period in 0 .. years {
				if period == years - 1 { schedule[period] = depreciable_cost - accumulated }
				else { accumulated += annual; schedule[period] = annual }
			}
		} else if method == 1 {
			mut book_value := purchase
			for period in 0 .. years {
				if period == years - 1 { schedule[period] = book_value - residual }
				else {
					expense := min_f64(book_value * rate, book_value - residual)
					schedule[period] = expense
					book_value -= expense
				}
			}
		} else if method == 2 {
			per_unit := depreciable_cost / f64(input[3])
			mut accumulated := 0.0
			for period in 0 .. years {
				if period == years - 1 { schedule[period] = depreciable_cost - accumulated }
				else {
					expense := f64(input[4 + period]) * per_unit
					accumulated += expense; schedule[period] = expense
				}
			}
		} else if method == 3 {
			syd := f64(years) * (f64(years) + 1.0) / 2.0
			mut accumulated := 0.0
			for period in 1 .. years + 1 {
				if period == years { schedule[period - 1] = depreciable_cost - accumulated }
				else {
					expense := (f64(years - period + 1) / syd) * depreciable_cost
					accumulated += expense; schedule[period - 1] = expense
				}
			}
		} else {
			ddb_rate := 2.0 / f64(years)
			mut book_value := purchase
			mut accumulated := 0.0
			for period in 1 .. years + 1 {
				remaining := f64(years - period + 1)
				ddb := max_f64(book_value * ddb_rate, 0.0)
				straight_line := max_f64((book_value - residual) / remaining, 0.0)
				expense := min_f64(max_f64(ddb, straight_line), book_value - residual)
				if period == years { schedule[period - 1] = depreciable_cost - accumulated }
				else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense }
			}
		}

		output_bytes := years * 8
		if output == nil || output_bytes > int(output_capacity) { return -2 }
		for index in 0 .. years { write_f64_le(mut output, index * 8, schedule[index]) }
		return i64(output_bytes)
	}
}
