module support_vector_classifier

import math

const max_n = 8
const max_d = 4
const max_q = 16
const max_input_values = 108

fn kernel_value(left []f64, right []f64, kind int) f64 {
	if kind == 0 {
		mut total := 0.0
		for i in 0 .. left.len { total += left[i] * right[i] }
		return total
	}
	mut norm_squared := 0.0
	for i in 0 .. left.len {
		difference := left[i] - right[i]
		norm_squared += difference * difference
	}
	return math.exp(-norm_squared)
}

fn fit_predict(labels []f64, training []f64, testing []f64,
	n int, dimension int, query_count int, kind int) i64 {
	mut kernel_matrix := [max_n * max_n]f64{}
	for i in 0 .. n {
		for j in 0 .. n {
			kernel_matrix[i * max_n + j] = kernel_value(
				training[i * max_d..i * max_d + dimension],
				training[j * max_d..j * max_d + dimension], kind)
		}
	}
	mut optimum := [max_n]f64{}
	for i in 0 .. n { optimum[i] = 0.5 }
	for iteration in 0 .. 5000 {
		mut gradient := [max_n]f64{}
		for i in 0 .. n {
			mut total := 0.0
			for j in 0 .. n { total += optimum[j] * labels[j] * kernel_matrix[i * max_n + j] }
			gradient[i] = labels[i] * total - 1.0
		}
		old_optimum := optimum
		learning_rate := 0.1 / (1.0 + f64(iteration) / 1000.0)
		for i in 0 .. n {
			mut updated := optimum[i] - learning_rate * gradient[i]
			if updated < 0.0 { updated = 0.0 }
			if updated > 1.0 { updated = 1.0 }
			optimum[i] = updated
		}
		mut sum_label_lambda := 0.0
		for i in 0 .. n { sum_label_lambda += optimum[i] * labels[i] }
		mut correction := sum_label_lambda / f64(n)
		for _ in 0 .. 10 {
			for i in 0 .. n {
				mut updated := optimum[i] - correction * labels[i]
				if updated < 0.0 { updated = 0.0 }
				if updated > 1.0 { updated = 1.0 }
				optimum[i] = updated
			}
			sum_label_lambda = 0.0
			for i in 0 .. n { sum_label_lambda += optimum[i] * labels[i] }
			correction = sum_label_lambda / f64(n)
			if math.abs(sum_label_lambda) < 1e-10 { break }
		}
		mut difference_squared := 0.0
		for i in 0 .. n {
			difference := optimum[i] - old_optimum[i]
			difference_squared += difference * difference
		}
		if math.sqrt(difference_squared) < 1e-8 { break }
	}

	mut offset_total := 0.0
	mut offset_count := 0
	for i in 0 .. n {
		if optimum[i] > 1e-5 && optimum[i] < 1.0 - 1e-5 {
			mut kernel_sum := 0.0
			for j in 0 .. n {
				kernel_sum += optimum[j] * labels[j] * kernel_value(
					training[j * max_d..j * max_d + dimension],
					training[i * max_d..i * max_d + dimension], kind)
			}
			offset_total += labels[i] - kernel_sum
			offset_count++
		}
	}
	if offset_count == 0 {
		for i in 0 .. n {
			mut kernel_sum := 0.0
			for j in 0 .. n {
				kernel_sum += optimum[j] * labels[j] * kernel_value(
					training[j * max_d..j * max_d + dimension],
					training[i * max_d..i * max_d + dimension], kind)
			}
			offset_total += labels[i] - kernel_sum
		}
		offset_total /= f64(n)
	} else {
		offset_total /= f64(offset_count)
	}

	mut mask := i64(0)
	for i in 0 .. query_count {
		mut total := 0.0
		for j in 0 .. n {
			total += optimum[j] * labels[j] * kernel_value(
				training[j * max_d..j * max_d + dimension],
				testing[i * max_d..i * max_d + dimension], kind)
		}
		if total + offset_total >= 0.0 { mask |= i64(1) << i }
	}
	return mask
}

@[export: 'support_vector_classifier']
pub fn support_vector_classifier(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input_values + 1 { return -1 }
		if input[0] < 2 || input[0] > max_n || input[1] < 1 || input[1] > max_d ||
			input[2] < 0 || input[2] > 1 || input[3] < 1 || input[3] > max_q { return -1 }
		n := int(input[0])
		dimension := int(input[1])
		kind := int(input[2])
		query_count := int(input[3])
		if length != usize(4 + n + n * dimension + query_count * dimension) { return -1 }
		mut labels := [max_n]f64{}
		mut saw_negative := false
		mut saw_positive := false
		for i in 0 .. n {
			label := input[4 + i]
			if label != -1 && label != 1 { return -1 }
			labels[i] = f64(label)
			if label < 0 { saw_negative = true } else { saw_positive = true }
		}
		if !saw_negative || !saw_positive { return -1 }
		mut training := [max_n * max_d]f64{}
		mut testing := [max_q * max_d]f64{}
		training_start := 4 + n
		for i in 0 .. n {
			for j in 0 .. dimension {
				value := input[training_start + i * dimension + j]
				if value < -4 || value > 4 { return -1 }
				training[i * max_d + j] = f64(value)
			}
		}
		testing_start := training_start + n * dimension
		for i in 0 .. query_count {
			for j in 0 .. dimension {
				value := input[testing_start + i * dimension + j]
				if value < -4 || value > 4 { return -1 }
				testing[i * max_d + j] = f64(value)
			}
		}
		return fit_predict(labels[..], training[..], testing[..], n, dimension, query_count, kind)
	}
}
