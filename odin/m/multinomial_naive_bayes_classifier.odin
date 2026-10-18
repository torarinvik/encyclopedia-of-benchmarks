package multinomial_naive_bayes_classifier

import "core:c"
import "core:math"

@(export)
multinomial_naive_bayes_classifier :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > 360 do return -1
	fit_count_value := input[0]
	if fit_count_value < 1 || fit_count_value > 2 do return -1
	fit_count := int(fit_count_value)
	position := 1
	feature_width := 0
	training_rows := i64(0)
	class_counts: [8]i64
	feature_sums: [64]f64
	class_totals: [8]f64
	labels: [16]i64
	training_features: [128]i64

	for _ in 0..<fit_count {
		if position+2 > int(input_length) do return -1
		rows_value := input[position]
		position += 1
		width_value := input[position]
		position += 1
		if rows_value < 1 || rows_value > 16 || width_value < 1 || width_value > 8 do return -1
		rows := int(rows_value)
		width := int(width_value)
		if position+rows+rows*width > int(input_length) do return -1
		for row in 0..<rows {
			label := input[position]
			position += 1
			if label < 0 || label > 7 do return -1
			labels[row] = label
		}
		for row in 0..<rows {
			for column in 0..<width {
				count := input[position]
				position += 1
				if count < 0 || count > 100 do return -1
				training_features[row*8+column] = count
			}
		}

		for label in 0..<8 {
			class_counts[label] = 0
			class_totals[label] = 0
		}
		for index in 0..<64 { feature_sums[index] = 0 }
		training_rows = rows_value
		feature_width = width
		for row in 0..<rows {
			label := int(labels[row])
			class_counts[label] += 1
			for column in 0..<width {
				count := f64(training_features[row*8+column])
				feature_sums[label*8+column] += count
				class_totals[label] += count
			}
		}
	}

	if position+2 > int(input_length) do return -1
	prediction_count_value := input[position]
	position += 1
	prediction_width_value := input[position]
	position += 1
	if prediction_count_value < 1 || prediction_count_value > 8 || prediction_width_value < 1 || prediction_width_value > 8 || int(prediction_width_value) != feature_width do return -1
	prediction_count := int(prediction_count_value)
	prediction_width := int(prediction_width_value)
	if position+prediction_count*prediction_width != int(input_length) do return -1
	prediction_features: [64]i64
	for row in 0..<prediction_count {
		for column in 0..<prediction_width {
			count := input[position]
			position += 1
			if count < 0 || count > 100 do return -1
			prediction_features[row*8+column] = count
		}
	}

	predictions: [8]i64
	for row in 0..<prediction_count {
		best_score := -1.0e300
		second_score := -1.0e300
		best_label := i64(-1)
		for label in 0..<8 {
			if class_counts[label] == 0 do continue
			score := math.ln_f64(f64(class_counts[label]) / f64(training_rows))
			denominator := class_totals[label] + f64(feature_width)
			for column in 0..<feature_width {
				likelihood := (feature_sums[label*8+column] + 1.0) / denominator
				score += f64(prediction_features[row*8+column]) * math.ln_f64(likelihood)
			}
			if score > best_score {
				second_score = best_score
				best_score = score
				best_label = i64(label)
			} else if score > second_score {
				second_score = score
			}
		}
		if best_label < 0 || (second_score > -1.0e299 && best_score-second_score < 1e-8) do return -1
		predictions[row] = best_label
	}

	output_words := prediction_count+1
	output_bytes := output_words*8
	if output == nil || output_capacity < c.size_t(output_bytes) || output_bytes > 72 do return -2
	fields: [9]i64
	fields[0] = prediction_count_value
	for index in 0..<prediction_count { fields[index+1] = predictions[index] }
	for index in 0..<output_words {
		bits := u64(fields[index])
		for byte in 0..<8 {
			output[index*8+byte] = u8(bits & 0xff)
			bits >>= 8
		}
	}
	return i64(output_bytes)
}
