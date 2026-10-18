package generate_risk_report

import "core:c"
import "core:math"

PI_VALUE :: 3.14159265358979323846264338327950288

qnorm_r_as241 :: proc "contextless" (probability: f64) -> f64 {
	q := probability - 0.5
	if math.abs(q) <= 0.425 {
		r := 0.180625 - q*q
		numerator := 2509.0809287301226727
		numerator = numerator*r + 33430.575583588128105
		numerator = numerator*r + 67265.770927008700853
		numerator = numerator*r + 45921.953931549871457
		numerator = numerator*r + 13731.693765509461125
		numerator = numerator*r + 1971.5909503065514427
		numerator = numerator*r + 133.14166789178437745
		numerator = numerator*r + 3.387132872796366608
		denominator := 5226.495278852854561
		denominator = denominator*r + 28729.085735721942674
		denominator = denominator*r + 39307.89580009271061
		denominator = denominator*r + 21213.794301586595867
		denominator = denominator*r + 5394.1960214247511077
		denominator = denominator*r + 687.1870074920579083
		denominator = denominator*r + 42.313330701600911252
		denominator = denominator*r + 1.0
		return q*numerator/denominator
	}
	r := math.sqrt_f64(-math.ln_f64(1.0-probability)) - 1.6
	numerator := 0.00077454501427834140764
	numerator = numerator*r + 0.0227238449892691845833
	numerator = numerator*r + 0.24178072517745061177
	numerator = numerator*r + 1.27045825245236838258
	numerator = numerator*r + 3.64784832476320460504
	numerator = numerator*r + 5.7694972214606914055
	numerator = numerator*r + 4.6303378461565452959
	numerator = numerator*r + 1.42343711074968357734
	denominator := 1.05075007164441684324e-9
	denominator = denominator*r + 0.0005475938084995344946
	denominator = denominator*r + 0.0151986665636164571966
	denominator = denominator*r + 0.14810397642748007459
	denominator = denominator*r + 0.68976733498510000455
	denominator = denominator*r + 1.6763848301838038494
	denominator = denominator*r + 2.05319162663775882187
	denominator = denominator*r + 1.0
	return numerator/denominator
}

@(export)
generate_risk_report :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < c.size_t(24) || input_length > c.size_t(69) do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	portfolio, confidence, horizon, count_value := input[0], input[1], input[2], input[3]
	if count_value < 20 || count_value > 64 || math.trunc(count_value) != count_value do return -1
	count := int(count_value)
	if input_length != c.size_t(4+count) || portfolio < 100 || portfolio > 1000000 ||
		confidence < 0.5 || confidence > 0.95 || horizon < 1 || horizon > 10 do return -1
	returns: [64]f64
	sum: f64 = 0
	for i in 0..<count {
		value := input[4+i]
		if value < -0.25 || value > 0.25 do return -1
		returns[i] = value
		sum += value
	}
	mean := sum/f64(count)
	squared_deviations: f64 = 0
	for i in 0..<count { difference := returns[i]-mean; squared_deviations += difference*difference }
	sample_sd := math.sqrt_f64(squared_deviations/f64(count-1))
	if sample_sd == 0 do return -1
	tail_count := int(math.floor((1-confidence)*f64(count)))
	if tail_count < 1 do return -1
	for i in 1..<count {
		value := returns[i]
		position := i
		for position > 0 && returns[position-1] > value {
			returns[position] = returns[position-1]
			position -= 1
		}
		returns[position] = value
	}
	tail_sum: f64 = 0
	for i in 0..<tail_count { tail_sum += returns[i] }
	scale := math.sqrt_f64(horizon)
	z := qnorm_r_as241(confidence)
	es_multiplier := math.exp_f64(-0.5*z*z)/math.sqrt_f64(2*PI_VALUE)/(1-confidence)
	third_moment: f64 = 0
	fourth_moment: f64 = 0
	for i in 0..<count {
		difference := returns[i]-mean
		square := difference*difference
		third_moment += square*difference
		fourth_moment += square*square
	}
	third_moment /= f64(count)
	fourth_moment /= f64(count)
	staged := [8]f64{
		-returns[tail_count-1]*portfolio*scale,
		-(tail_sum/f64(tail_count))*portfolio*scale,
		portfolio*(z*sample_sd-mean)*scale,
		portfolio*(es_multiplier*sample_sd-mean)*scale,
		mean,
		sample_sd,
		third_moment/(sample_sd*sample_sd*sample_sd),
		fourth_moment/(sample_sd*sample_sd*sample_sd*sample_sd)-3,
	}
	if output == nil || capacity < c.size_t(8) do return -2
	for i in 0..<8 { output[i] = staged[i] }
	return 8
}
