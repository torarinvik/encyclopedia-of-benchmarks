import math

const max_parseable_input_length = usize(62)
const z_95 = 1.6448536269514722

@[export: 'update_returns']
pub fn update_returns(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. int(input_length) {
			if !input[index].is_finite() { return -1 }
		}

		raw_count := input[0]
		if raw_count < 2.0 || raw_count > 60.0 || raw_count != f64(int(raw_count)) { return -1 }
		count := int(raw_count)
		if input_length != usize(1 + count) { return -1 }

		mut staged := [63]f64{}
		mut sum := f64(0.0)
		for index in 0 .. count {
			value := input[index + 1]
			if value < -0.25 || value > 0.25 { return -1 }
			staged[index] = value
			sum += value
		}
		mean := sum / f64(count)
		mut squared_deviation_sum := f64(0.0)
		for index in 0 .. count {
			deviation := staged[index] - mean
			squared_deviation_sum += deviation * deviation
		}
		volatility := math.sqrt(squared_deviation_sum / f64(count - 1))
		if !mean.is_finite() || !volatility.is_finite() || volatility == 0.0 { return -1 }
		parametric_var := 100000.0 * (z_95 * volatility - mean)
		if !parametric_var.is_finite() { return -1 }

		staged[count] = mean
		staged[count + 1] = volatility
		staged[count + 2] = parametric_var
		result_length := count + 3
		if output == nil || output_capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length {
			output[index] = staged[index]
		}
		return i64(result_length)
	}
}
