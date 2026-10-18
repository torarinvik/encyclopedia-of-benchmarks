module generate_risk_report

import math

const pi_value = 3.14159265358979323846264338327950288

fn qnorm_r_as241(probability f64) f64 {
	q := probability - 0.5
	if q.abs() <= 0.425 {
		r := 0.180625 - q * q
		mut numerator := 2509.0809287301226727
		numerator = numerator * r + 33430.575583588128105
		numerator = numerator * r + 67265.770927008700853
		numerator = numerator * r + 45921.953931549871457
		numerator = numerator * r + 13731.693765509461125
		numerator = numerator * r + 1971.5909503065514427
		numerator = numerator * r + 133.14166789178437745
		numerator = numerator * r + 3.387132872796366608
		mut denominator := 5226.495278852854561
		denominator = denominator * r + 28729.085735721942674
		denominator = denominator * r + 39307.89580009271061
		denominator = denominator * r + 21213.794301586595867
		denominator = denominator * r + 5394.1960214247511077
		denominator = denominator * r + 687.1870074920579083
		denominator = denominator * r + 42.313330701600911252
		denominator = denominator * r + 1.0
		return q * numerator / denominator
	}
	r := math.sqrt(-math.log(1.0 - probability)) - 1.6
	mut numerator := 0.00077454501427834140764
	numerator = numerator * r + 0.0227238449892691845833
	numerator = numerator * r + 0.24178072517745061177
	numerator = numerator * r + 1.27045825245236838258
	numerator = numerator * r + 3.64784832476320460504
	numerator = numerator * r + 5.7694972214606914055
	numerator = numerator * r + 4.6303378461565452959
	numerator = numerator * r + 1.42343711074968357734
	mut denominator := 1.05075007164441684324e-9
	denominator = denominator * r + 0.0005475938084995344946
	denominator = denominator * r + 0.0151986665636164571966
	denominator = denominator * r + 0.14810397642748007459
	denominator = denominator * r + 0.68976733498510000455
	denominator = denominator * r + 1.6763848301838038494
	denominator = denominator * r + 2.05319162663775882187
	denominator = denominator * r + 1.0
	return numerator / denominator
}

@[export: 'generate_risk_report']
pub fn generate_risk_report(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 24 || input_length > 69 { return -1 }
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		portfolio := input[0]
		confidence := input[1]
		horizon := input[2]
		count_value := input[3]
		if count_value < 20.0 || count_value > 64.0 || math.floor(count_value) != count_value { return -1 }
		count := int(count_value)
		if input_length != 4 + usize(count) || portfolio < 100.0 || portfolio > 1000000.0 ||
			confidence < 0.5 || confidence > 0.95 || horizon < 1.0 || horizon > 10.0 { return -1 }
		mut returns := [64]f64{}
		mut sum := 0.0
		for i in 0 .. count {
			value := input[4 + i]
			if value < -0.25 || value > 0.25 { return -1 }
			returns[i] = value
			sum += value
		}
		mean := sum / f64(count)
		mut squared_deviations := 0.0
		for i in 0 .. count {
			difference := returns[i] - mean
			squared_deviations += difference * difference
		}
		sample_sd := math.sqrt(squared_deviations / f64(count - 1))
		if sample_sd == 0.0 { return -1 }
		tail_count := int(math.floor((1.0 - confidence) * f64(count)))
		if tail_count < 1 { return -1 }
		for i in 1 .. count {
			value := returns[i]
			mut position := i
			for position > 0 && returns[position - 1] > value {
				returns[position] = returns[position - 1]
				position--
			}
			returns[position] = value
		}
		mut tail_sum := 0.0
		for i in 0 .. tail_count { tail_sum += returns[i] }
		scale := math.sqrt(horizon)
		z := qnorm_r_as241(confidence)
		es_multiplier := math.exp(-0.5 * z * z) / math.sqrt(2.0 * pi_value) / (1.0 - confidence)
		mut third_moment := 0.0
		mut fourth_moment := 0.0
		for i in 0 .. count {
			difference := returns[i] - mean
			square := difference * difference
			third_moment += square * difference
			fourth_moment += square * square
		}
		third_moment /= f64(count)
		fourth_moment /= f64(count)
		staged := [8]f64{
			-returns[tail_count - 1] * portfolio * scale,
			-(tail_sum / f64(tail_count)) * portfolio * scale,
			portfolio * (z * sample_sd - mean) * scale,
			portfolio * (es_multiplier * sample_sd - mean) * scale,
			mean,
			sample_sd,
			third_moment / (sample_sd * sample_sd * sample_sd),
			fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0,
		}
		if isnil(output) || capacity < 8 { return -2 }
		for i in 0 .. 8 { output[i] = staged[i] }
		return 8
	}
}
