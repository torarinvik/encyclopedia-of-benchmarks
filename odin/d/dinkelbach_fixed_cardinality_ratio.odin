package dinkelbach_fixed_cardinality_ratio

import "core:c"

MAX_ITEMS :: 12
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(27)
RATIO_BASE :: i64(120_001)

gcd_positive :: proc "contextless" (a_input, b_input: i64) -> i64 {
	a, b := a_input, b_input
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

choose_count :: proc "contextless" (n, k: int) -> int {
	count := 1
	for i := 1; i <= k; i += 1 { count = count * (n - i + 1) / i }
	return count
}

@(export)
dinkelbach_fixed_cardinality_ratio :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, selected_count_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_ITEMS || selected_count_value < 1 || selected_count_value > n_value do return -1
	n, selected_count := int(n_value), int(selected_count_value)
	if length != c.size_t(2 + 2 * n) do return -1

	var numerators: [MAX_ITEMS]i64
	var denominators: [MAX_ITEMS]i64
	for item := 0; item < n; item += 1 {
		numerator, denominator := input[2+2*item], input[3+2*item]
		if numerator < 0 || numerator > 10_000 || denominator < 1 || denominator > 10_000 do return -1
		numerators[item], denominators[item] = numerator, denominator
	}

	current_numerator, current_denominator := i64(0), i64(1)
	iteration_limit := choose_count(n, selected_count)
	for step := 0; step <= iteration_limit; step += 1 {
		var residuals: [MAX_ITEMS]i64
		var order: [MAX_ITEMS]int
		for item := 0; item < n; item += 1 {
			residuals[item] = numerators[item] * current_denominator - current_numerator * denominators[item]
			order[item] = item
		}
		for position := 1; position < n; position += 1 {
			candidate := order[position]
			insertion := position
			for insertion > 0 {
				previous := order[insertion-1]
				if residuals[candidate] > residuals[previous] ||
					(residuals[candidate] == residuals[previous] && candidate < previous) {
					order[insertion] = previous
					insertion -= 1
				} else { break }
			}
			order[insertion] = candidate
		}

		numerator_total, denominator_total := i64(0), i64(0)
		for rank := 0; rank < selected_count; rank += 1 {
			item := order[rank]
			numerator_total += numerators[item]
			denominator_total += denominators[item]
		}
		residual_total := numerator_total * current_denominator - current_numerator * denominator_total
		if residual_total == 0 {
			divisor := gcd_positive(numerator_total, denominator_total)
			return (numerator_total / divisor) * RATIO_BASE + denominator_total / divisor
		}
		if residual_total < 0 do return -1
		divisor := gcd_positive(numerator_total, denominator_total)
		current_numerator, current_denominator = numerator_total / divisor, denominator_total / divisor
	}
	return -1
}
