module thiele_rational_interpolation

const max_n = 6
const max_input = 15
const grid_denominator = 18014398509481984.0
const min_node_separation = 0.0625
const low_magnitude = 0.03125000023283064365386963
const magnitude_cap = 63.99999999976716935634613037

fn grid_value(value f64) bool {
	if !value.is_finite() || value < -8.0 || value > 8.0 { return false }
	scaled := value * grid_denominator
	return f64(i64(scaled)) == scaled
}

fn guarded_magnitude(value f64) bool {
	return (value > low_magnitude && value < magnitude_cap) ||
		(value < -low_magnitude && value > -magnitude_cap)
}

fn below_cap(value f64) bool {
	return value.is_finite() && value > -magnitude_cap && value < magnitude_cap
}

@[export: 'thiele_rational_interpolation']
pub fn thiele_rational_interpolation(input &f64, input_length usize,
		mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > max_input { return -1 }
		n_value := input[0]
		if !grid_value(n_value) || f64(i64(n_value)) != n_value || n_value < 1.0 || n_value > 6.0 { return -1 }
		n := int(n_value)
		if input_length != usize(2 + 2 * n) { return -1 }

		mut x := [6]f64{}
		mut y := [6]f64{}
		mut difference := [36]f64{}
		for i in 0 .. n {
			x[i] = input[1 + 2 * i]
			y[i] = input[2 + 2 * i]
			if !grid_value(x[i]) || !grid_value(y[i]) { return -1 }
			for j in 0 .. i {
				gap := x[i] - x[j]
				if gap == 0.0 || (gap < min_node_separation && gap > -min_node_separation) { return -1 }
			}
			difference[i] = y[i]
		}
		query := input[input_length - 1]
		if !grid_value(query) { return -1 }

		for order in 1 .. n {
			for endpoint in order .. n {
				denominator := difference[(order - 1) * max_n + order - 1] - difference[(order - 1) * max_n + endpoint]
				if !denominator.is_finite() || !guarded_magnitude(denominator) { return -1 }
				value := (x[order - 1] - x[endpoint]) / denominator
				if !below_cap(value) { return -1 }
				difference[order * max_n + endpoint] = value
			}
			if !guarded_magnitude(difference[order * max_n + order]) { return -1 }
		}

		mut result := f64(0.0)
		mut at_node := false
		for i in 0 .. n {
			if query == x[i] { result = y[i]; at_node = true; break }
		}
		if !at_node && n == 1 { result = y[0] }
		if !at_node && n > 1 {
			mut tail := difference[(n - 1) * max_n + n - 1]
			mut order := n - 2
			for order > 0 {
				if !guarded_magnitude(tail) { return -1 }
				tail = difference[order * max_n + order] + (query - x[order]) / tail
				if !below_cap(tail) { return -1 }
				order--
			}
			if !guarded_magnitude(tail) { return -1 }
			result = y[0] + (query - x[0]) / tail
		}
		if !below_cap(result) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		output[0] = result
		return 1
	}
}
