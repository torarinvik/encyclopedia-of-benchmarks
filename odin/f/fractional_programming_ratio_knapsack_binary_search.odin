package fractional_programming_ratio_knapsack_binary_search

import "core:c"

MAX_ITEMS :: 12
MAX_WEIGHT :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(27)
RATIO_SCALE :: i64(1_000_000)
MAX_SCALED_RATIO :: i64(1_000_000_000)
NEGATIVE_INFINITY :: i64(-2_305_843_009_213_693_952)

ratio_feasible :: proc "contextless" (numerators, denominators: [MAX_ITEMS]i64,
                                      n, required_weight: int, threshold: i64) -> bool {
	var current: [MAX_WEIGHT + 1]i64
	var next: [MAX_WEIGHT + 1]i64
	for weight := 0; weight <= required_weight; weight += 1 { current[weight] = NEGATIVE_INFINITY }
	current[0] = 0
	for item := 0; item < n; item += 1 {
		for weight := 0; weight <= required_weight; weight += 1 { next[weight] = current[weight] }
		score := RATIO_SCALE * numerators[item] - threshold * denominators[item]
		for weight := 0; weight <= required_weight; weight += 1 {
			if current[weight] == NEGATIVE_INFINITY do continue
			sum_weight := weight + int(denominators[item])
			target := sum_weight
			if target > required_weight do target = required_weight
			candidate := current[weight] + score
			if candidate > next[target] do next[target] = candidate
		}
		current = next
	}
	return current[required_weight] >= 0
}

@(export)
fractional_programming_ratio_knapsack_binary_search :: proc "c" (input: [^]i64,
                                                                   length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, required_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_ITEMS || required_value < 1 || required_value > MAX_WEIGHT do return -1
	n, required_weight := int(n_value), int(required_value)
	if length != c.size_t(2 + 2 * n) do return -1

	var numerators: [MAX_ITEMS]i64
	var denominators: [MAX_ITEMS]i64
	denominator_sum := i64(0)
	for item := 0; item < n; item += 1 {
		numerator, denominator := input[2+2*item], input[3+2*item]
		if numerator < 0 || numerator > 1000 || denominator < 1 || denominator > 8 do return -1
		numerators[item], denominators[item] = numerator, denominator
		denominator_sum += denominator
	}
	if required_value > denominator_sum do return -1

	low, high := i64(0), MAX_SCALED_RATIO + 1
	for high-low > 1 {
		middle := low + (high-low)/2
		if ratio_feasible(numerators, denominators, n, required_weight, middle) {
			low = middle
		} else {
			high = middle
		}
	}
	return low
}
