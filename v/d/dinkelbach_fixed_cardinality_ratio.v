module dinkelbach_fixed_cardinality_ratio

const max_n = 12
const max_input = 26
const max_parseable = 27

fn dfr_gcd(left i64, right i64) i64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn dfr_before(a int, b int, scores [12]i64) bool {
	if scores[a] != scores[b] { return scores[a] > scores[b] }
	return a < b
}

@[export: 'dinkelbach_fixed_cardinality_ratio']
pub fn dinkelbach_fixed_cardinality_ratio(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable) { return -1 }
		n_value, k_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || k_value < 1 || k_value > n_value { return -1 }
		n, k := int(n_value), int(k_value)
		if int(length) != 2 + 2 * n || length > usize(max_input) { return -1 }

		mut numerators := [max_n]i64{}
		mut denominators := [max_n]i64{}
		for index in 0 .. n {
			a_value, b_value := input[2 + 2 * index], input[3 + 2 * index]
			if a_value < 0 || a_value > 10000 || b_value < 1 || b_value > 10000 { return -1 }
			numerators[index], denominators[index] = a_value, b_value
		}

		mut combination_count := 1
		for step in 0 .. k { combination_count = combination_count * (n - step) / (step + 1) }
		mut ratio_numerator := i64(0)
		mut ratio_denominator := i64(1)
		for _ in 0 .. combination_count + 1 {
			mut scores := [max_n]i64{}
			mut order := [max_n]int{}
			for index in 0 .. n {
				scores[index] = numerators[index] * ratio_denominator - ratio_numerator * denominators[index]
				order[index] = index
			}
			for index in 1 .. n {
				item := order[index]
				mut position := index
				for position > 0 && dfr_before(item, order[position - 1], scores) {
					order[position] = order[position - 1]
					position--
				}
				order[position] = item
			}
			mut selected_numerator := i64(0)
			mut selected_denominator := i64(0)
			for index in 0 .. k {
				selected_numerator += numerators[order[index]]
				selected_denominator += denominators[order[index]]
			}
			residual := selected_numerator * ratio_denominator - ratio_numerator * selected_denominator
			if residual == 0 {
				divisor := dfr_gcd(selected_numerator, selected_denominator)
				return (selected_numerator / divisor) * 120001 + selected_denominator / divisor
			}
			if residual < 0 { return -1 }
			divisor := dfr_gcd(selected_numerator, selected_denominator)
			ratio_numerator = selected_numerator / divisor
			ratio_denominator = selected_denominator / divisor
		}
		return -1
	}
}
