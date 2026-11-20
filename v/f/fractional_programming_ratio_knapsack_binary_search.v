module fractional_programming_ratio_knapsack_binary_search

const max_n = 12
const max_weight = 32
const max_parseable = 27
const ratio_scale = i64(1_000_000)
const max_scaled_ratio = i64(1_000_000_000)
const negative_infinity = i64(-2_305_843_009_213_693_952)

fn ratio_feasible(numerators [12]i64, denominators [12]i64, n int,
	required_weight int, threshold i64) bool {
	mut current := [33]i64{}
	mut next := [33]i64{}
	for weight in 0 .. required_weight + 1 { current[weight] = negative_infinity }
	current[0] = 0
	for item in 0 .. n {
		for weight in 0 .. required_weight + 1 { next[weight] = current[weight] }
		score := ratio_scale * numerators[item] - threshold * denominators[item]
		for weight in 0 .. required_weight + 1 {
			if current[weight] == negative_infinity { continue }
			sum_weight := weight + int(denominators[item])
			target := if sum_weight < required_weight { sum_weight } else { required_weight }
			candidate := current[weight] + score
			if candidate > next[target] { next[target] = candidate }
		}
		current = next
	}
	return current[required_weight] >= 0
}

@[export: 'fractional_programming_ratio_knapsack_binary_search']
pub fn fractional_programming_ratio_knapsack_binary_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable) { return -1 }
		n_value, required_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || required_value < 1 || required_value > max_weight { return -1 }
		n, required_weight := int(n_value), int(required_value)
		if int(length) != 2 + 2 * n { return -1 }
		mut numerators := [max_n]i64{}
		mut denominators := [max_n]i64{}
		mut denominator_sum := i64(0)
		for item in 0 .. n {
			numerator, denominator := input[2 + 2 * item], input[3 + 2 * item]
			if numerator < 0 || numerator > 1000 || denominator < 1 || denominator > 8 { return -1 }
			numerators[item], denominators[item] = numerator, denominator
			denominator_sum += denominator
		}
		if required_value > denominator_sum { return -1 }
		mut low := i64(0)
		mut high := max_scaled_ratio + 1
		for high - low > 1 {
			middle := low + (high - low) / 2
			if ratio_feasible(numerators, denominators, n, required_weight, middle) {
				low = middle
			} else {
				high = middle
			}
		}
		return low
	}
}
