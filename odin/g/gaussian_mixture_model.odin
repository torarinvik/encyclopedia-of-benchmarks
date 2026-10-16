package gaussian_mixture_model

import "core:c"
import "core:math"

MAX_SAMPLES :: 16
MAX_INPUT_LENGTH :: 19
PI :: 3.14159265358979323846264338327950288

gaussian_mixture_pdf :: proc "contextless" (value, mean, variance: f64) -> f64 {
	difference := value - mean
	return math.exp_f64(-(difference * difference) / (2.0 * variance)) / math.sqrt_f64(2.0 * PI * variance)
}

@(export)
gaussian_mixture_model :: proc "c" (values: [^]i64, length: c.size_t,
									 output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	count_value, max_iterations, tolerance_micro := values[0], values[1], values[2]
	if count_value < 2 || count_value > MAX_SAMPLES || max_iterations < 1 || max_iterations > 20 do return -1
	if tolerance_micro < 1 || tolerance_micro > 1000 do return -1
	count := int(count_value)
	if int(length) != 3 + count do return -1
	data: [MAX_SAMPLES]f64
	previous_sample: i64 = -5001
	for index in 0..<count {
		sample := values[3+index]
		if sample < -5000 || sample > 5000 || sample < previous_sample do return -1
		previous_sample = sample
		data[index] = f64(sample) / 1000.0
	}
	required := count + 1
	if output == nil || capacity < c.size_t(required) do return -2

	data_mean: f64 = 0
	for index in 0..<count do data_mean += data[index]
	data_mean /= f64(count)
	variance: f64 = 0
	for index in 0..<count {
		difference := data[index] - data_mean
		variance += difference * difference
	}
	variance = variance / f64(count-1) + 1e-6
	weights := [2]f64{0.5, 0.5}
	means := [2]f64{data[0], data[count-1]}
	variances := [2]f64{variance, variance}
	responsibilities: [2][MAX_SAMPLES]f64
	tolerance := f64(tolerance_micro) / 1_000_000.0
	previous_likelihood: f64 = 0
	has_previous_likelihood := false
	iterations := 0

	for iteration in 0..<int(max_iterations) {
		component_counts := [2]f64{0, 0}
		for index in 0..<count {
			probability0 := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0])
			probability1 := weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
			total := probability0 + probability1
			if total == 0 do return -1
			responsibilities[0][index] = probability0 / total
			responsibilities[1][index] = probability1 / total
			component_counts[0] += responsibilities[0][index]
			component_counts[1] += responsibilities[1][index]
		}
		if component_counts[0] <= 0 || component_counts[1] <= 0 do return -1
		for component in 0..<2 {
			weights[component] = component_counts[component] / f64(count)
			weighted_sum: f64 = 0
			for index in 0..<count do weighted_sum += responsibilities[component][index] * data[index]
			means[component] = weighted_sum / component_counts[component]
			covariance: f64 = 0
			for index in 0..<count {
				difference := data[index] - means[component]
				covariance += responsibilities[component][index] * difference * difference
			}
			variances[component] = covariance / component_counts[component] + 1e-6
		}
		likelihood: f64 = 0
		for index in 0..<count {
			density := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0]) +
				weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
			likelihood += math.ln_f64(density + 1e-12)
		}
		iterations = iteration + 1
		likelihood_change := likelihood - previous_likelihood
		if likelihood_change < 0 do likelihood_change = -likelihood_change
		if has_previous_likelihood && likelihood_change < tolerance do break
		previous_likelihood = likelihood
		has_previous_likelihood = true
	}
	output[0] = u8(iterations)
	for index in 0..<count {
		probability0 := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0])
		probability1 := weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
		output[index+1] = 1
		if probability0 >= probability1 do output[index+1] = 0
	}
	return i64(required)
}
