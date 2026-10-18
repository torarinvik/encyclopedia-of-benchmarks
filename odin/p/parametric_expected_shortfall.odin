package parametric_expected_shortfall

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(69)
SQRT_TWO_PI :: f64(2.50662827463100050242)

normal_quantile :: proc "contextless" (probability: f64) -> f64 {
	q := probability - 0.5
	if math.abs(q) <= 0.425 {
		r := 0.180625 - q*q
		numerator := 2509.0809287301226727
		for coefficient in [7]f64{33430.575583588128105, 67265.770927008700853,
			45921.953931549871457, 13731.693765509461125, 1971.5909503065514427,
			133.14166789178437745, 3.387132872796366608} {
			numerator = numerator*r + coefficient
		}
		denominator := 5226.495278852854561
		for coefficient in [7]f64{28729.085735721942674, 39307.89580009271061,
			21213.794301586595867, 5394.1960214247511077, 687.1870074920579083,
			42.313330701600911252, 1.0} {
			denominator = denominator*r + coefficient
		}
		return q*numerator/denominator
	}
	r := math.sqrt_f64(-math.ln_f64(1.0-probability)) - 1.6
	numerator := 7.7454501427834140764e-4
	for coefficient in [7]f64{0.0227238449892691845833, 0.24178072517745061177,
		1.27045825245236838258, 3.64784832476320460504, 5.7694972214606914055,
		4.6303378461565452959, 1.42343711074968357734} {
		numerator = numerator*r + coefficient
	}
	denominator := 1.05075007164441684324e-9
	for coefficient in [7]f64{5.475938084995344946e-4, 0.0151986665636164571966,
		0.14810397642748007459, 0.68976733498510000455, 1.6763848301838038494,
		2.05319162663775882187, 1.0} {
		denominator = denominator*r + coefficient
	}
	value := numerator/denominator
	if q < 0.0 do value = -value
	return value
}

@(export)
calculate_es_parametric :: proc "c" (input: [^]f64, length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if math.is_nan(input[index]) || math.is_inf(input[index]) do return -1
	}
	portfolio, confidence, horizon, raw_count := input[0], input[1], input[2], input[3]
	if portfolio < 100.0 || portfolio > 1_000_000.0 || confidence < 0.5 || confidence > 0.95 ||
		horizon < 1.0 || horizon > 10.0 || raw_count < 20.0 || raw_count > 64.0 ||
		math.floor_f64(raw_count) != raw_count do return -1
	count := int(raw_count)
	if length != c.size_t(4 + count) do return -1
	total := 0.0
	for index := 0; index < count; index += 1 {
		value := input[4 + index]
		if value < -0.25 || value > 0.25 do return -1
		total += value
	}
	mean := total/f64(count)
	squared_deviations := 0.0
	for index := 0; index < count; index += 1 {
		difference := input[4 + index] - mean
		squared_deviations += difference*difference
	}
	sample_sd := math.sqrt_f64(squared_deviations/f64(count-1))
	if output == nil || output_capacity < 1 do return -2
	z := normal_quantile(confidence)
	density := math.exp_f64(-0.5*z*z)/SQRT_TWO_PI
	multiplier := density/(1.0-confidence)
	result := portfolio*(multiplier*sample_sd-mean)*math.sqrt_f64(horizon)
	output[0] = result
	return 1
}
