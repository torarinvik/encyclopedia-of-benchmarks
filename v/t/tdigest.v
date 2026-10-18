module tdigest

import math

const min_compression = 10
const max_compression = 20
const max_samples = 32
const max_queries = 4
const max_input_length = 45
const max_valid_input_length = 44
const max_output_length = 10
const two_pi = 2.0 * math.pi

fn quantile_limit(compression f64, q f64) f64 {
	mut bounded := q
	if bounded < 0.0 { bounded = 0.0 }
	if bounded > 1.0 { bounded = 1.0 }
	k := compression / two_pi * math.asin(2.0 * bounded - 1.0) + 1.0
	angle := k * two_pi / compression
	if angle >= math.pi / 2.0 { return 1.0 }
	if angle <= -math.pi / 2.0 { return 0.0 }
	return (math.sin(angle) + 1.0) / 2.0
}

fn interpolate(x0 f64, y0 f64, x1 f64, y1 f64, x f64) f64 {
	if x1 <= x0 { return y1 }
	return y0 + (x - x0) / (x1 - x0) * (y1 - y0)
}

@[export: 'tdigest']
pub fn tdigest(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if input == nil || input_length < 7 || input_length > max_input_length { return -1 }
	unsafe {
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		compression_value := input[0]
		sample_count_value := input[1]
		if compression_value != math.floor(compression_value) || compression_value < min_compression || compression_value > max_compression ||
			sample_count_value != math.floor(sample_count_value) || sample_count_value < 1 || sample_count_value > max_samples { return -1 }
		compression := int(compression_value)
		sample_count := int(sample_count_value)
		quantile_count_index := 2 + sample_count
		if input_length <= quantile_count_index { return -1 }
		quantile_count_value := input[quantile_count_index]
		if quantile_count_value != math.floor(quantile_count_value) || quantile_count_value < 1 || quantile_count_value > max_queries { return -1 }
		quantile_count := int(quantile_count_value)
		quantile_start := quantile_count_index + 1
		cdf_count_index := quantile_start + quantile_count
		if input_length <= cdf_count_index { return -1 }
		cdf_count_value := input[cdf_count_index]
		if cdf_count_value != math.floor(cdf_count_value) || cdf_count_value < 1 || cdf_count_value > max_queries { return -1 }
		cdf_count := int(cdf_count_value)
		cdf_start := cdf_count_index + 1
		if input_length != cdf_start + cdf_count || input_length > max_valid_input_length { return -1 }

		mut samples := [max_samples]f64{}
		for i in 0 .. sample_count {
			value := input[2 + i]
			if value < -8.0 || value > 8.0 || value != math.floor(value) { return -1 }
			samples[i] = value
		}
		mut probabilities := [max_queries]f64{}
		for i in 0 .. quantile_count {
			value := input[quantile_start + i]
			if value < 0.0 || value > 1.0 || value * 4.0 != math.floor(value * 4.0) { return -1 }
			probabilities[i] = value
		}
		mut cdf_values := [max_queries]f64{}
		for i in 0 .. cdf_count {
			value := input[cdf_start + i]
			if value < -8.0 || value > 8.0 || value != math.floor(value) { return -1 }
			cdf_values[i] = value
		}

		mut sorted := samples
		for i in 1 .. sample_count {
			value := sorted[i]
			mut position := i
			for position > 0 && sorted[position - 1] > value {
				sorted[position] = sorted[position - 1]
				position--
			}
			sorted[position] = value
		}

		mut means := [max_samples]f64{}
		mut weights := [max_samples]f64{}
		mut centroid_count := 1
		means[0] = sorted[0]
		weights[0] = 1.0
		mut closed_weight := 0.0
		total_weight := f64(sample_count)
		mut weight_limit := total_weight * quantile_limit(f64(compression), 0.0)
		centroid_capacity := 2 * (compression + 2)
		mut last := 0
		for i in 1 .. sample_count {
			projected := weights[last] + 1.0
			room_left := closed_weight + projected <= weight_limit
			if room_left || last == centroid_capacity - 1 {
				weights[last] = projected
				means[last] += (sorted[i] - means[last]) / projected
			} else {
				closed_weight += weights[last]
				weight_limit = total_weight * quantile_limit(f64(compression), closed_weight / total_weight)
				last++
				means[last] = sorted[i]
				weights[last] = 1.0
				centroid_count++
			}
		}

		mut staged := [max_output_length]f64{}
		mut output_index := 0
		staged[output_index] = f64(quantile_count)
		output_index++
		minimum := sorted[0]
		maximum := sorted[sample_count - 1]
		for query in 0 .. quantile_count {
			q := probabilities[query]
			mut result := 0.0
			if centroid_count == 1 { result = means[0] }
			else {
				index := q * total_weight
				if index <= 0.0 { result = minimum }
				else if index >= total_weight { result = maximum }
				else {
					mut previous_value := minimum
					mut previous_index := 0.0
					mut current_index := 0.0
					mut found := false
					for i in 0 .. centroid_count {
						if i == 0 { current_index += weights[i] / 2.0 }
						else { current_index += (weights[i - 1] + weights[i]) / 2.0 }
						if index < current_index {
							result = interpolate(previous_index, previous_value, current_index, means[i], index)
							found = true
							break
						}
						previous_value = means[i]
						previous_index = current_index
					}
					if !found { result = interpolate(previous_index, previous_value, total_weight, maximum, index) }
				}
			}
			staged[output_index] = result
			output_index++
		}
		staged[output_index] = f64(cdf_count)
		output_index++
		for query in 0 .. cdf_count {
			value := cdf_values[query]
			mut result := 0.0
			if value < minimum { result = 0.0 }
			else if value > maximum { result = 1.0 }
			else if maximum <= minimum { result = 0.5 }
			else {
				mut previous_value := minimum
				mut previous_index := 0.0
				mut current_index := 0.0
				mut found := false
				for i in 0 .. centroid_count {
					if i == 0 { current_index += weights[i] / 2.0 }
					else { current_index += (weights[i - 1] + weights[i]) / 2.0 }
					if value < means[i] {
						result = interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight
						found = true
						break
					}
					previous_value = means[i]
					previous_index = current_index
				}
				if !found { result = interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight }
			}
			staged[output_index] = result
			output_index++
		}

		if output == nil || output_capacity < usize(output_index) { return -2 }
		for i in 0 .. output_index { output[i] = staged[i] }
		return i64(output_index)
	}
}
