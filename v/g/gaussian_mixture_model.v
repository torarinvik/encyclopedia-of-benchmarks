import math

const max_samples = 16
const max_input_length = 19
const pi = 3.14159265358979323846264338327950288

fn gaussian_mixture_pdf(value f64, mean f64, variance f64) f64 {
	difference := value - mean
	return math.exp(-(difference * difference) / (2.0 * variance)) / math.sqrt(2.0 * pi * variance)
}

@[export: 'gaussian_mixture_model']
pub fn gaussian_mixture_model(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 3 || length > max_input_length || unsafe { values == nil } { return -1 }
	count_value := unsafe { values[0] }
	max_iterations := unsafe { values[1] }
	tolerance_micro := unsafe { values[2] }
	if count_value < 2 || count_value > max_samples || max_iterations < 1 || max_iterations > 20 ||
		tolerance_micro < 1 || tolerance_micro > 1000 { return -1 }
	count := int(count_value)
	if length != usize(3 + count) { return -1 }
	mut data := [max_samples]f64{}
	mut previous_sample := i64(-5001)
	for index := 0; index < count; index++ {
		sample := unsafe { values[3 + index] }
		if sample < -5000 || sample > 5000 || sample < previous_sample { return -1 }
		previous_sample = sample
		data[index] = f64(sample) / 1000.0
	}
	required := count + 1
	if capacity < required || isnil(output) { return -2 }

	mut data_mean := f64(0)
	for index := 0; index < count; index++ { data_mean += data[index] }
	data_mean /= f64(count)
	mut variance := f64(0)
	for index := 0; index < count; index++ {
		difference := data[index] - data_mean
		variance += difference * difference
	}
	variance = variance / f64(count - 1) + 1e-6
	mut weights := [2]f64{}
	weights[0] = 0.5
	weights[1] = 0.5
	mut means := [2]f64{}
	means[0] = data[0]
	means[1] = data[count - 1]
	mut variances := [2]f64{}
	variances[0] = variance
	variances[1] = variance
	mut responsibilities := [2][max_samples]f64{}
	tolerance := f64(tolerance_micro) / 1_000_000.0
	mut previous_likelihood := f64(0)
	mut has_previous_likelihood := false
	mut iterations := 0

	for iteration := 0; iteration < int(max_iterations); iteration++ {
		mut component_counts := [2]f64{}
		for index := 0; index < count; index++ {
			probability0 := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0])
			probability1 := weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
			total := probability0 + probability1
			if total == 0.0 { return -1 }
			responsibilities[0][index] = probability0 / total
			responsibilities[1][index] = probability1 / total
			component_counts[0] += responsibilities[0][index]
			component_counts[1] += responsibilities[1][index]
		}
		if component_counts[0] <= 0.0 || component_counts[1] <= 0.0 { return -1 }
		for component := 0; component < 2; component++ {
			weights[component] = component_counts[component] / f64(count)
			mut weighted_sum := f64(0)
			for index := 0; index < count; index++ { weighted_sum += responsibilities[component][index] * data[index] }
			means[component] = weighted_sum / component_counts[component]
			mut covariance := f64(0)
			for index := 0; index < count; index++ {
				difference := data[index] - means[component]
				covariance += responsibilities[component][index] * difference * difference
			}
			variances[component] = covariance / component_counts[component] + 1e-6
		}
		mut likelihood := f64(0)
		for index := 0; index < count; index++ {
			density := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0]) +
				weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
			likelihood += math.log(density + 1e-12)
		}
		iterations = iteration + 1
		if has_previous_likelihood && math.abs(likelihood - previous_likelihood) < tolerance { break }
		previous_likelihood = likelihood
		has_previous_likelihood = true
	}
	unsafe { output[0] = u8(iterations) }
	for index := 0; index < count; index++ {
		probability0 := weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0])
		probability1 := weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1])
		unsafe { output[index + 1] = if probability0 >= probability1 { u8(0) } else { u8(1) } }
	}
	return i64(required)
}
