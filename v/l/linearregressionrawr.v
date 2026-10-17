module linearregressionrawr

const min_sample_count = 2
const max_sample_count = 32
const max_parseable_input_length = 66
const max_output_elements = 2

fn exact_integer_in_range(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

fn rounded_divide(numerator f64, denominator f64) f64 @noinline {
	return numerator / denominator
}

@[export: 'linearregressionrawr']
pub fn linearregressionrawr(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. input_length {
			if !input[index].is_finite() { return -1 }
		}

		if !exact_integer_in_range(input[0], min_sample_count, max_sample_count) { return -1 }
		sample_count := int(input[0])
		if input_length != usize(1 + 2 * sample_count) { return -1 }

		mut predictor_sum := i64(0)
		mut response_sum := i64(0)
		mut cross_product_sum := i64(0)
		mut predictor_square_sum := i64(0)
		mut first_predictor := i64(0)
		mut predictors_are_constant := true
		for index in 0 .. sample_count {
			predictor_value := input[1 + index]
			response_value := input[1 + sample_count + index]
			if !exact_integer_in_range(predictor_value, -4, 4) ||
				!exact_integer_in_range(response_value, -16, 16) { return -1 }

			predictor := i64(predictor_value)
			response := i64(response_value)
			if index == 0 { first_predictor = predictor }
			else if predictor != first_predictor { predictors_are_constant = false }

			predictor_sum += predictor
			response_sum += response
			cross_product_sum += predictor * response
			predictor_square_sum += predictor * predictor
		}
		if predictor_sum != 0 || predictors_are_constant || predictor_square_sum == 0 { return -1 }

		staged := [2]f64{
			rounded_divide(f64(response_sum), f64(sample_count)),
			rounded_divide(f64(cross_product_sum), f64(predictor_square_sum)),
		}
		if output == nil || output_capacity < max_output_elements { return -2 }
		for index in 0 .. max_output_elements { output[index] = staged[index] }
		return i64(max_output_elements)
	}
}
