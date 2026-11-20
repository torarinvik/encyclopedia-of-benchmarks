module jury_discrete_time_stability_predicate

@[export: 'jury_discrete_time_stability_predicate']
pub fn jury_discrete_time_stability_predicate(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 7 { return -1 }
	unsafe {
		degree := input[0]
		if degree < 1 || degree > 4 || length != usize(degree + 2) { return -1 }
		mut coefficients := [5]i64{}
		for index in 0 .. int(degree + 1) {
			value := input[index + 1]
			if value < -9 || value > 9 || (index == 0 && value == 0) { return -1 }
			coefficients[index] = value
		}
		if coefficients[0] < 0 {
			for index in 0 .. int(degree + 1) { coefficients[index] = -coefficients[index] }
		}

		mut at_one := i64(0)
		mut at_minus_one := i64(0)
		for index in 0 .. int(degree + 1) {
			at_one += coefficients[index]
			if (int(degree) - index) % 2 == 0 { at_minus_one += coefficients[index] }
			else { at_minus_one -= coefficients[index] }
		}
		if at_one <= 0 || ((degree % 2 == 0 && at_minus_one <= 0) ||
		                   (degree % 2 != 0 && at_minus_one >= 0)) { return 0 }

		mut row := [5]i64{}
		mut reduced := [5]i64{}
		for index in 0 .. int(degree + 1) { row[index] = coefficients[index] }
		mut current_degree := int(degree)
		for current_degree >= 1 {
			trailing := row[current_degree]
			trailing_magnitude := if trailing < 0 { -trailing } else { trailing }
			if row[0] <= trailing_magnitude { return 0 }
			if current_degree == 1 { break }
			for index in 0 .. current_degree {
				reduced[index] = row[0] * row[index] - trailing * row[current_degree - index]
			}
			for index in 0 .. current_degree { row[index] = reduced[index] }
			current_degree--
		}
		return 1
	}
}
