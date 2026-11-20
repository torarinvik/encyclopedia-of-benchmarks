package jury_discrete_time_stability_predicate

import "core:c"

MAX_PARSEABLE_LENGTH :: c.size_t(7)

@(export)
jury_discrete_time_stability_predicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	degree := input[0]
	if degree < 1 || degree > 4 || length != c.size_t(degree + 2) do return -1

	coefficients: [5]i64 = {}
	for index := i64(0); index <= degree; index += 1 {
		value := input[c.size_t(index + 1)]
		if value < -9 || value > 9 || (index == 0 && value == 0) do return -1
		coefficients[index] = value
	}
	if coefficients[0] < 0 {
		for index := i64(0); index <= degree; index += 1 do coefficients[index] = -coefficients[index]
	}

	at_one := i64(0)
	at_minus_one := i64(0)
	for index := i64(0); index <= degree; index += 1 {
		at_one += coefficients[index]
		if (degree - index) % 2 == 0 do at_minus_one += coefficients[index]
		else do at_minus_one -= coefficients[index]
	}
	if at_one <= 0 || ((degree % 2 == 0 && at_minus_one <= 0) ||
	                   (degree % 2 != 0 && at_minus_one >= 0)) do return 0

	row: [5]i64 = {}
	reduced: [5]i64 = {}
	for index := i64(0); index <= degree; index += 1 do row[index] = coefficients[index]
	for current_degree := degree; current_degree >= 1; current_degree -= 1 {
		trailing := row[current_degree]
		trailing_magnitude := trailing
		if trailing < 0 do trailing_magnitude = -trailing
		if row[0] <= trailing_magnitude do return 0
		if current_degree == 1 do break
		for index := i64(0); index < current_degree; index += 1 {
			reduced[index] = row[0] * row[index] - trailing * row[current_degree - index]
		}
		for index := i64(0); index < current_degree; index += 1 do row[index] = reduced[index]
	}
	return 1
}
