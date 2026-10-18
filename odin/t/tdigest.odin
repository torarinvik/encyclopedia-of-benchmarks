package tdigest

import "core:c"
import "core:math"

MIN_COMPRESSION :: 10
MAX_COMPRESSION :: 20
MAX_SAMPLES :: 32
MAX_QUERIES :: 4
MAX_INPUT_LENGTH :: 45
MAX_VALID_INPUT_LENGTH :: 44
MAX_OUTPUT_LENGTH :: 10
TWO_PI :: 2.0 * math.PI

quantile_limit :: proc(compression, q: f64) -> f64 {
	bounded := q
	if bounded < 0.0 do bounded = 0.0
	if bounded > 1.0 do bounded = 1.0
	k := compression / TWO_PI * math.asin_f64(2.0 * bounded - 1.0) + 1.0
	angle := k * TWO_PI / compression
	if angle >= math.PI / 2.0 do return 1.0
	if angle <= -math.PI / 2.0 do return 0.0
	return (math.sin_f64(angle) + 1.0) / 2.0
}

interpolate :: proc(x0, y0, x1, y1, x: f64) -> f64 {
	if x1 <= x0 do return y1
	return y0 + (x - x0) / (x1 - x0) * (y1 - y0)
}

finite_value :: proc(value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

@(export)
tdigest :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 7 || input_length > MAX_INPUT_LENGTH do return -1
	for index := 0; index < int(input_length); index += 1 {
		if !finite_value(input[index]) do return -1
	}
	compression_value, sample_count_value := input[0], input[1]
	if compression_value != math.floor_f64(compression_value) || compression_value < f64(MIN_COMPRESSION) || compression_value > f64(MAX_COMPRESSION) ||
		sample_count_value != math.floor_f64(sample_count_value) || sample_count_value < 1.0 || sample_count_value > f64(MAX_SAMPLES) do return -1
	compression, sample_count := int(compression_value), int(sample_count_value)
	quantile_count_index := 2 + sample_count
	if int(input_length) <= quantile_count_index do return -1
	quantile_count_value := input[quantile_count_index]
	if quantile_count_value != math.floor_f64(quantile_count_value) || quantile_count_value < 1.0 || quantile_count_value > f64(MAX_QUERIES) do return -1
	quantile_count := int(quantile_count_value)
	quantile_start := quantile_count_index + 1
	cdf_count_index := quantile_start + quantile_count
	if int(input_length) <= cdf_count_index do return -1
	cdf_count_value := input[cdf_count_index]
	if cdf_count_value != math.floor_f64(cdf_count_value) || cdf_count_value < 1.0 || cdf_count_value > f64(MAX_QUERIES) do return -1
	cdf_count := int(cdf_count_value)
	cdf_start := cdf_count_index + 1
	if int(input_length) != cdf_start + cdf_count || int(input_length) > MAX_VALID_INPUT_LENGTH do return -1

	samples: [MAX_SAMPLES]f64 = {}
	for index := 0; index < sample_count; index += 1 {
		value := input[2 + index]
		if value < -8.0 || value > 8.0 || value != math.floor_f64(value) do return -1
		samples[index] = value
	}
	probabilities: [MAX_QUERIES]f64
	for index := 0; index < quantile_count; index += 1 {
		value := input[quantile_start + index]
		if value < 0.0 || value > 1.0 || value * 4.0 != math.floor_f64(value * 4.0) do return -1
		probabilities[index] = value
	}
	cdf_values: [MAX_QUERIES]f64
	for index := 0; index < cdf_count; index += 1 {
		value := input[cdf_start + index]
		if value < -8.0 || value > 8.0 || value != math.floor_f64(value) do return -1
		cdf_values[index] = value
	}

	sorted := samples
	for index := 1; index < sample_count; index += 1 {
		value := sorted[index]
		position := index
		for position > 0 && sorted[position - 1] > value {
			sorted[position] = sorted[position - 1]
			position -= 1
		}
		sorted[position] = value
	}

	means: [MAX_SAMPLES]f64
	weights: [MAX_SAMPLES]f64
	centroid_count := 1
	means[0], weights[0] = sorted[0], 1.0
	closed_weight := 0.0
	total_weight := f64(sample_count)
	weight_limit := total_weight * quantile_limit(f64(compression), 0.0)
	centroid_capacity := 2 * (compression + 2)
	last := 0
	for index := 1; index < sample_count; index += 1 {
		projected := weights[last] + 1.0
		room_left := closed_weight + projected <= weight_limit
		if room_left || last == centroid_capacity - 1 {
			weights[last] = projected
			means[last] += (sorted[index] - means[last]) / projected
		} else {
			closed_weight += weights[last]
			weight_limit = total_weight * quantile_limit(f64(compression), closed_weight / total_weight)
			last += 1
			means[last], weights[last] = sorted[index], 1.0
			centroid_count += 1
		}
	}

	staged: [MAX_OUTPUT_LENGTH]f64
	output_index := 0
	staged[output_index] = f64(quantile_count)
	output_index += 1
	minimum, maximum := sorted[0], sorted[sample_count-1]
	for query := 0; query < quantile_count; query += 1 {
		q := probabilities[query]
		result := f64(0.0)
		if centroid_count == 1 do result = means[0]
		else {
			index := q * total_weight
			if index <= 0.0 do result = minimum
			else if index >= total_weight do result = maximum
			else {
				previous_value, previous_index, current_index := minimum, f64(0.0), f64(0.0)
				found := false
				for i := 0; i < centroid_count; i += 1 {
					if i == 0 do current_index += weights[i] / 2.0
					else do current_index += (weights[i - 1] + weights[i]) / 2.0
					if index < current_index {
						result = interpolate(previous_index, previous_value, current_index, means[i], index)
						found = true
						break
					}
					previous_value, previous_index = means[i], current_index
				}
				if !found do result = interpolate(previous_index, previous_value, total_weight, maximum, index)
			}
		}
		staged[output_index] = result
		output_index += 1
	}
	staged[output_index] = f64(cdf_count)
	output_index += 1
	for query := 0; query < cdf_count; query += 1 {
		value := cdf_values[query]
		result := f64(0.0)
		if value < minimum do result = 0.0
		else if value > maximum do result = 1.0
		else if maximum <= minimum do result = 0.5
		else {
			previous_value, previous_index, current_index := minimum, f64(0.0), f64(0.0)
			found := false
			for i := 0; i < centroid_count; i += 1 {
				if i == 0 do current_index += weights[i] / 2.0
				else do current_index += (weights[i - 1] + weights[i]) / 2.0
				if value < means[i] {
					result = interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight
					found = true
					break
				}
				previous_value, previous_index = means[i], current_index
			}
			if !found do result = interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight
		}
		staged[output_index] = result
		output_index += 1
	}

	if output == nil || output_capacity < c.size_t(output_index) do return -2
	for index := 0; index < output_index; index += 1 { output[index] = staged[index] }
	return i64(output_index)
}
