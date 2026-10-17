module laplace_transformation

import math

const max_input_length = usize(68)
const max_sample_count = 64
const min_sample_micro = i64(-1_000_000)
const max_sample_micro = i64(1_000_000)
const invalid_result = -1.0e300

@[export: 'laplace_transformation']
pub fn laplace_transformation(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		sample_count_value := input[0]
		s_milli := input[1]
		dt_micro := input[2]
		if sample_count_value < 1 || sample_count_value > max_sample_count { return invalid_result }
		sample_count := int(sample_count_value)
		if length != usize(sample_count + 3) || s_milli < 0 || s_milli > 1000 ||
			dt_micro < 1 || dt_micro > 1_000_000 { return invalid_result }

		mut samples := [max_sample_count]f64{}
		for index in 0 .. sample_count {
			sample := input[3 + index]
			if sample < min_sample_micro || sample > max_sample_micro { return invalid_result }
			samples[index] = f64(sample) / 1_000_000.0
		}
		if sample_count == 1 { return 0.0 }

		s_value := f64(s_milli) / 1000.0
		delta_t := f64(dt_micro) / 1_000_000.0
		stop := f64(sample_count - 1) * delta_t
		step := stop / f64(sample_count - 1)
		mut integrand := [max_sample_count]f64{}
		for index in 0 .. sample_count {
			time := if index == sample_count - 1 { stop } else { f64(index) * step }
			integrand[index] = samples[index] * math.exp(-s_value * time)
		}

		mut result := 0.0
		for index in 0 .. sample_count - 1 {
			result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0
		}
		return result
	}
}
