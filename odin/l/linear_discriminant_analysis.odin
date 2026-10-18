package linear_discriminant_analysis

import "core:c"
import "core:math"

MAX_CLASSES :: 4
MAX_SAMPLES :: 16
MAX_INPUT :: 22
MIN_MARGIN :: 1e-8

exact_integer :: proc(value: f64, minimum, maximum: f64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < minimum || value > maximum do return false
	return f64(i64(value)) == value
}

@(export)
linear_discriminant_analysis :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length == 0 || input_length > MAX_INPUT do return -1
	if !exact_integer(input[0], 2, 4) do return -1
	class_count := int(input[0])
	if input_length < c.size_t(1+class_count) do return -1
	counts: [MAX_CLASSES]int
	total_count := 0
	for k := 0; k < class_count; k += 1 {
		if !exact_integer(input[1+k], 2, 6) do return -1
		counts[k] = int(input[1+k])
		total_count += counts[k]
	}
	if total_count > MAX_SAMPLES || input_length != c.size_t(1+class_count+total_count) do return -1
	groups: [MAX_CLASSES][6]f64
	means: [MAX_CLASSES]f64
	offset := 1+class_count
	for k := 0; k < class_count; k += 1 {
		sum: f64 = 0
		for j := 0; j < counts[k]; j += 1 {
			x := input[offset]; offset += 1
			if !exact_integer(x, -32, 32) do return -1
			groups[k][j] = x
			sum += x
		}
		means[k] = sum/f64(counts[k])
		if !exact_integer(means[k], -32, 32) do return -1
	}
	squared_sum: f64 = 0
	for k := 0; k < class_count; k += 1 {
		for j := 0; j < counts[k]; j += 1 { delta := groups[k][j]-means[k]; squared_sum += delta*delta }
	}
	variance := (1.0/f64(total_count-class_count))*squared_sum
	if math.is_nan(variance) || math.is_inf(variance) || variance <= 0 do return -1
	priors: [MAX_CLASSES]f64
	for k := 0; k < class_count; k += 1 { priors[k] = f64(counts[k])/f64(total_count) }
	staged: [MAX_SAMPLES]f64
	n := 0
	for group := 0; group < class_count; group += 1 {
		for j := 0; j < counts[group]; j += 1 {
			x := groups[group][j]
			best, second: f64 = -1e300, -1e300
			winner := 0
			for k := 0; k < class_count; k += 1 {
				score := x*(means[k]/variance)-(means[k]*means[k]/(2.0*variance))+math.ln_f64(priors[k])
				if score > best { second=best; best=score; winner=k } else if score > second { second=score }
			}
			if math.is_nan(best) || math.is_inf(best) || best-second < MIN_MARGIN do return -1
			staged[n] = f64(winner); n += 1
		}
	}
	if output == nil || capacity < c.size_t(n) do return -2
	for i := 0; i < n; i += 1 { output[i] = staged[i] }
	return i64(n)
}
