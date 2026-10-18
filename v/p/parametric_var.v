import math

const max_parseable_input_length = usize(69)

fn qnorm(confidence f64) f64 {
	q := confidence - 0.5
	if math.abs(q) <= 0.425 {
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
		return q * (numerator / denominator)
	}
	r := math.sqrt(-math.log(1.0 - confidence)) - 1.6
	mut numerator := 7.7454501427834140764e-4
	numerator = numerator * r + 0.0227238449892691845833
	numerator = numerator * r + 0.24178072517745061177
	numerator = numerator * r + 1.27045825245236838258
	numerator = numerator * r + 3.64784832476320460504
	numerator = numerator * r + 5.7694972214606914055
	numerator = numerator * r + 4.6303378461565452959
	numerator = numerator * r + 1.42343711074968357734
	mut denominator := 1.05075007164441684324e-9
	denominator = denominator * r + 5.475938084995344946e-4
	denominator = denominator * r + 0.0151986665636164571966
	denominator = denominator * r + 0.14810397642748007459
	denominator = denominator * r + 0.68976733498510000455
	denominator = denominator * r + 1.6763848301838038494
	denominator = denominator * r + 2.05319162663775882187
	denominator = denominator * r + 1.0
	return numerator / denominator
}

@[export: 'calculate_var_parametric']
pub fn calculate_var_parametric(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 24 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. int(input_length) {
			if !input[index].is_finite() { return -1 }
		}

		portfolio_value, confidence_level, time_horizon, count_value := input[0], input[1], input[2], input[3]
		if count_value < 20.0 || count_value > 64.0 || count_value != f64(int(count_value)) { return -1 }
		return_count := int(count_value)
		if input_length != usize(4 + return_count) || portfolio_value < 100.0 || portfolio_value > 1_000_000.0 ||
			confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0 { return -1 }

		mut mean := f64(0.0)
		for index in 0 .. return_count {
			value := input[4 + index]
			if value < -0.25 || value > 0.25 { return -1 }
			mean += value
		}
		mean /= f64(return_count)
		mut squared_deviations := f64(0.0)
		for index in 0 .. return_count {
			difference := input[4 + index] - mean
			squared_deviations += difference * difference
		}
		sample_sd := math.sqrt(squared_deviations / f64(return_count - 1))
		result := portfolio_value * (qnorm(confidence_level) * sample_sd - mean) * math.sqrt(time_horizon)
		if output == nil || output_capacity < 1 { return -2 }
		output[0] = result
		return 1
	}
}
