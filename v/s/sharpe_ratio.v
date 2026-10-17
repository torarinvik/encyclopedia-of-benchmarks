module sharpe_ratio

import math

const max_parseable_length = 67
const max_sample_count = i64(64)
const scale = 1_000_000.0
const min_return_micro = i64(-200_000)
const max_return_micro = i64(200_000)
const min_risk_free_micro = i64(-100_000)
const max_risk_free_micro = i64(100_000)
const invalid_result = -1.0e300

@[export: 'sharpe_ratio']
pub fn sharpe_ratio(values &i64, length usize) f64 {
	unsafe {
		if values == nil || length < 2 || length > usize(max_parseable_length) { return invalid_result }
		count_value := values[0]
		if count_value < 2 || count_value > max_sample_count || length != usize(count_value + 2) { return invalid_result }
		count := int(count_value)
		risk_free_micro := values[count + 1]
		if risk_free_micro < min_risk_free_micro || risk_free_micro > max_risk_free_micro { return invalid_result }

		mut sum := 0.0
		mut constant_returns := true
		for index in 0 .. count {
			return_micro := values[index + 1]
			if return_micro < min_return_micro || return_micro > max_return_micro { return invalid_result }
			if return_micro != values[1] { constant_returns = false }
			sum += f64(return_micro) / scale
		}
		if constant_returns { return invalid_result }

		mean := sum / f64(count)
		risk_free_rate := f64(risk_free_micro) / scale
		excess_return := mean - risk_free_rate
		mut squared_deviations := 0.0
		for index in 0 .. count {
			return_value := f64(values[index + 1]) / scale
			difference := return_value - mean
			squared_deviations += math.pow(difference, 2.0)
		}
		variance := squared_deviations / f64(count - 1)
		standard_deviation := math.sqrt(variance)
		if standard_deviation == 0.0 { return invalid_result }
		return excess_return / standard_deviation
	}
}
