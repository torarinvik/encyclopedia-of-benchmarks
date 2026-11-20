module berlekamp_welch_rs_decode;

const usz FIELD = 7, MAX_N = 7, MAX_K = 3, MAX_T = 2, MAX_VARS = 8, MAX_POLY = 5;

fn long mod7(long value) {
	value %= 7;
	return value < 0 ? value + 7 : value;
}

fn long inverse7(long value) {
	switch (value) {
		case 1: return 1;
		case 2: return 4;
		case 3: return 5;
		case 4: return 2;
		case 5: return 3;
		case 6: return 6;
		default: return 0;
	}
}

fn long decode(usz n, usz k, usz errors, long* received) {
	usz q_count = k + errors;
	usz e_count = errors + 1;
	usz variable_count = q_count + e_count;
	long[MAX_N * MAX_VARS] matrix = {};
	for (usz row = 0; row < n; ++row) {
		long[MAX_POLY] powers = {1};
		for (usz degree = 1; degree < MAX_POLY; ++degree)
			powers[degree] = powers[degree - 1] * (long)row % 7;
		for (usz degree = 0; degree < q_count; ++degree)
			matrix[row * MAX_VARS + degree] = powers[degree];
		for (usz degree = 0; degree < e_count; ++degree)
			matrix[row * MAX_VARS + q_count + degree] = mod7(-received[row] * powers[degree]);
	}

	usz[MAX_VARS] pivot_columns = {};
	bool[MAX_VARS] is_pivot = {};
	usz pivot_row = 0;
	for (usz column = 0; column < variable_count && pivot_row < n; ++column) {
		usz found = pivot_row;
		while (found < n && matrix[found * MAX_VARS + column] == 0) found += 1;
		if (found == n) continue;
		for (usz c = 0; c < variable_count; ++c) {
			long temporary = matrix[pivot_row * MAX_VARS + c];
			matrix[pivot_row * MAX_VARS + c] = matrix[found * MAX_VARS + c];
			matrix[found * MAX_VARS + c] = temporary;
		}
		long inverse = inverse7(matrix[pivot_row * MAX_VARS + column]);
		for (usz c = 0; c < variable_count; ++c)
			matrix[pivot_row * MAX_VARS + c] = matrix[pivot_row * MAX_VARS + c] * inverse % 7;
		for (usz row = 0; row < n; ++row) {
			if (row == pivot_row) continue;
			long factor = matrix[row * MAX_VARS + column];
			if (factor == 0) continue;
			for (usz c = 0; c < variable_count; ++c)
				matrix[row * MAX_VARS + c] = mod7(matrix[row * MAX_VARS + c]
					- factor * matrix[pivot_row * MAX_VARS + c]);
		}
		pivot_columns[pivot_row] = column;
		is_pivot[column] = true;
		pivot_row += 1;
	}
	usz free_column = variable_count;
	for (usz column = 0; column < variable_count; ++column) {
		if (!is_pivot[column]) { free_column = column; break; }
	}
	if (free_column == variable_count) return 0;
	long[MAX_VARS] solution = {};
	solution[free_column] = 1;
	for (usz row = 0; row < pivot_row; ++row)
		solution[pivot_columns[row]] = mod7(-matrix[row * MAX_VARS + free_column]);

	long[MAX_POLY] locator = {};
	long[MAX_POLY] remainder = {};
	for (usz degree = 0; degree < q_count; ++degree) remainder[degree] = solution[degree];
	for (usz degree = 0; degree < e_count; ++degree) locator[degree] = solution[q_count + degree];
	bool locator_zero = true;
	for (usz degree = 0; degree < e_count; ++degree)
		if (locator[degree] != 0) locator_zero = false;
	if (locator_zero) return 0;
	usz locator_degree = e_count - 1;
	while (locator_degree > 0 && locator[locator_degree] == 0) locator_degree -= 1;
	usz remainder_degree = q_count - 1;
	while (remainder_degree > 0 && remainder[remainder_degree] == 0) remainder_degree -= 1;
	bool numerator_zero = true;
	for (usz degree = 0; degree < q_count; ++degree)
		if (remainder[degree] != 0) numerator_zero = false;
	usz quotient_count = 1;
	if (!numerator_zero && remainder_degree >= locator_degree)
		quotient_count = remainder_degree - locator_degree + 1;
	long[MAX_POLY] quotient = {};
	long inverse_lead = inverse7(locator[locator_degree]);
	while (!numerator_zero && remainder_degree >= locator_degree) {
		usz shift = remainder_degree - locator_degree;
		long factor = remainder[remainder_degree] * inverse_lead % 7;
		quotient[shift] = factor;
		for (usz degree = 0; degree <= locator_degree; ++degree)
			remainder[shift + degree] = mod7(remainder[shift + degree] - factor * locator[degree]);
		while (remainder_degree > 0 && remainder[remainder_degree] == 0) remainder_degree -= 1;
		numerator_zero = true;
		for (usz degree = 0; degree < q_count; ++degree)
			if (remainder[degree] != 0) numerator_zero = false;
	}
	for (usz degree = 0; degree < q_count; ++degree)
		if (remainder[degree] != 0) return 0;
	if (quotient_count > k) return 0;

	long[MAX_K] coefficients = {};
	for (usz degree = 0; degree < quotient_count; ++degree) coefficients[degree] = quotient[degree];
	usz mismatches = 0;
	for (usz x = 0; x < n; ++x) {
		long value = 0;
		usz degree = k;
		while (degree > 0) {
			degree -= 1;
			value = (value * (long)x + coefficients[degree]) % 7;
		}
		if (value != received[x]) mismatches += 1;
	}
	if (mismatches > errors) return 0;
	long result = 1, place = 1;
	for (usz degree = 0; degree < k; ++degree) {
		result += coefficients[degree] * place;
		place *= 7;
	}
	return result;
}

fn long berlekamp_welch_rs_decode(long* input, usz length)
		@export("berlekamp_welch_rs_decode") {
	if (input == null || length < 3 || length > 11) return -1;
	long n_value = input[0], k_value = input[1], t_value = input[2];
	if (n_value < 2 || n_value > (long)MAX_N || k_value < 1 || k_value > (long)MAX_K
			|| k_value > n_value || t_value < 0 || t_value > (long)MAX_T
			|| 2 * t_value > n_value - k_value) return -1;
	usz n = (usz)n_value, k = (usz)k_value, errors = (usz)t_value;
	if (length != 3 + n) return -1;
	long[MAX_N] received = {};
	for (usz index = 0; index < n; ++index) {
		long symbol = input[3 + index];
		if (symbol < 0 || symbol >= (long)FIELD) return -1;
		received[index] = symbol;
	}
	return decode(n, k, errors, &received[0]);
}
