package support_vector_classifier

import "core:c"
import "core:math"

MAX_N :: 8
MAX_D :: 4
MAX_Q :: 16
MAX_INPUT_VALUES :: 108

kernel_value :: proc "contextless" (left, right: []f64, kind: int) -> f64 {
	if kind == 0 {
		total := 0.0
		for i := 0; i < len(left); i += 1 { total += left[i] * right[i] }
		return total
	}
	norm_squared := 0.0
	for i := 0; i < len(left); i += 1 {
		difference := left[i] - right[i]
		norm_squared += difference * difference
	}
	return math.exp(-norm_squared)
}

fit_predict :: proc "contextless" (labels, training, testing: []f64,
	n, dimension, query_count, kind: int) -> i64 {
	var kernel_matrix: [MAX_N * MAX_N]f64
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			kernel_matrix[i * MAX_N + j] = kernel_value(
				training[i * MAX_D:i * MAX_D + dimension],
				training[j * MAX_D:j * MAX_D + dimension], kind)
		}
	}
	var optimum: [MAX_N]f64
	for i := 0; i < n; i += 1 { optimum[i] = 0.5 }
	for iteration := 0; iteration < 5000; iteration += 1 {
		var gradient: [MAX_N]f64
		for i := 0; i < n; i += 1 {
			total := 0.0
			for j := 0; j < n; j += 1 {
				total += optimum[j] * labels[j] * kernel_matrix[i * MAX_N + j]
			}
			gradient[i] = labels[i] * total - 1.0
		}
		old_optimum := optimum
		learning_rate := 0.1 / (1.0 + f64(iteration) / 1000.0)
		for i := 0; i < n; i += 1 {
			updated := optimum[i] - learning_rate * gradient[i]
			if updated < 0.0 { updated = 0.0 }
			if updated > 1.0 { updated = 1.0 }
			optimum[i] = updated
		}
		sum_label_lambda := 0.0
		for i := 0; i < n; i += 1 { sum_label_lambda += optimum[i] * labels[i] }
		correction := sum_label_lambda / f64(n)
		for pass := 0; pass < 10; pass += 1 {
			for i := 0; i < n; i += 1 {
				updated := optimum[i] - correction * labels[i]
				if updated < 0.0 { updated = 0.0 }
				if updated > 1.0 { updated = 1.0 }
				optimum[i] = updated
			}
			sum_label_lambda = 0.0
			for i := 0; i < n; i += 1 { sum_label_lambda += optimum[i] * labels[i] }
			correction = sum_label_lambda / f64(n)
			if math.abs(sum_label_lambda) < 1e-10 { break }
		}
		difference_squared := 0.0
		for i := 0; i < n; i += 1 {
			difference := optimum[i] - old_optimum[i]
			difference_squared += difference * difference
		}
		if math.sqrt(difference_squared) < 1e-8 { break }
	}

	offset_total := 0.0
	offset_count := 0
	for i := 0; i < n; i += 1 {
		if optimum[i] > 1e-5 && optimum[i] < 1.0 - 1e-5 {
			kernel_sum := 0.0
			for j := 0; j < n; j += 1 {
				kernel_sum += optimum[j] * labels[j] * kernel_value(
					training[j * MAX_D:j * MAX_D + dimension],
					training[i * MAX_D:i * MAX_D + dimension], kind)
			}
			offset_total += labels[i] - kernel_sum
			offset_count += 1
		}
	}
	if offset_count == 0 {
		for i := 0; i < n; i += 1 {
			kernel_sum := 0.0
			for j := 0; j < n; j += 1 {
				kernel_sum += optimum[j] * labels[j] * kernel_value(
					training[j * MAX_D:j * MAX_D + dimension],
					training[i * MAX_D:i * MAX_D + dimension], kind)
			}
			offset_total += labels[i] - kernel_sum
		}
		offset_total /= f64(n)
	} else {
		offset_total /= f64(offset_count)
	}

	mask := i64(0)
	for i := 0; i < query_count; i += 1 {
		total := 0.0
		for j := 0; j < n; j += 1 {
			total += optimum[j] * labels[j] * kernel_value(
				training[j * MAX_D:j * MAX_D + dimension],
				testing[i * MAX_D:i * MAX_D + dimension], kind)
		}
		if total + offset_total >= 0.0 { mask |= i64(1) << i }
	}
	return mask
}

@(export, link_name="support_vector_classifier")
support_vector_classifier :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_VALUES + 1) do return -1
	if input[0] < 2 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_D ||
		input[2] < 0 || input[2] > 1 || input[3] < 1 || input[3] > MAX_Q do return -1
	n, dimension, kind, query_count := int(input[0]), int(input[1]), int(input[2]), int(input[3])
	if int(length) != 4 + n + n*dimension + query_count*dimension do return -1
	var labels: [MAX_N]f64
	saw_negative, saw_positive := false, false
	for i := 0; i < n; i += 1 {
		label := input[4+i]
		if label != -1 && label != 1 do return -1
		labels[i] = f64(label)
		if label < 0 { saw_negative = true } else { saw_positive = true }
	}
	if !saw_negative || !saw_positive do return -1
	var training: [MAX_N * MAX_D]f64
	var testing: [MAX_Q * MAX_D]f64
	training_start := 4 + n
	for i := 0; i < n; i += 1 {
		for j := 0; j < dimension; j += 1 {
			value := input[training_start + i*dimension + j]
			if value < -4 || value > 4 do return -1
			training[i*MAX_D+j] = f64(value)
		}
	}
	testing_start := training_start + n*dimension
	for i := 0; i < query_count; i += 1 {
		for j := 0; j < dimension; j += 1 {
			value := input[testing_start + i*dimension + j]
			if value < -4 || value > 4 do return -1
			testing[i*MAX_D+j] = f64(value)
		}
	}
	return fit_predict(labels[:], training[:], testing[:], n, dimension, query_count, kind)
}
