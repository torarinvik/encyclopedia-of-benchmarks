module gao_rs_decode;

const usz FIELD = 7, MAX_N = 7, MAX_K = 3, POLY = 8;

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

fn bool poly_zero(long* polynomial) {
	for (usz degree = 0; degree < POLY; ++degree)
		if (polynomial[degree] != 0) return false;
	return true;
}

fn usz poly_degree(long* polynomial) {
	for (usz degree = POLY; degree > 0; --degree)
		if (polynomial[degree - 1] != 0) return degree - 1;
	return 0;
}

fn void poly_copy(long* destination, long* source) {
	for (usz degree = 0; degree < POLY; ++degree) destination[degree] = source[degree];
}

fn void multiply_linear(long* polynomial, long root) {
	long[POLY] product = {};
	for (usz degree = 0; degree < POLY; ++degree) {
		product[degree] = mod7(product[degree] - root * polynomial[degree]);
		if (degree + 1 < POLY)
			product[degree + 1] = mod7(product[degree + 1] + polynomial[degree]);
	}
	poly_copy(polynomial, &product[0]);
}

fn void interpolate(usz n, long* values, long* result) {
	for (usz i = 0; i < n; ++i) {
		long[POLY] basis = {1};
		long denominator = 1;
		for (usz j = 0; j < n; ++j) {
			if (j == i) continue;
			multiply_linear(&basis[0], (long)j);
			denominator = mod7(denominator * ((long)i - (long)j));
		}
		long scale = mod7(values[i] * inverse7(denominator));
		for (usz degree = 0; degree < POLY; ++degree)
			result[degree] = mod7(result[degree] + scale * basis[degree]);
	}
}

fn void build_vanishing(usz n, long* result) {
	result[0] = 1;
	for (usz point = 0; point < n; ++point) multiply_linear(result, (long)point);
}

fn bool divide_poly(long* numerator, long* denominator, long* quotient, long* remainder) {
	if (poly_zero(denominator)) return false;
	for (usz degree = 0; degree < POLY; ++degree) {
		quotient[degree] = 0;
		remainder[degree] = numerator[degree];
	}
	usz denominator_degree = poly_degree(denominator);
	usz remainder_degree = poly_degree(remainder);
	long inverse_lead = inverse7(denominator[denominator_degree]);
	while (!poly_zero(remainder) && remainder_degree >= denominator_degree) {
		usz shift = remainder_degree - denominator_degree;
		long factor = mod7(remainder[remainder_degree] * inverse_lead);
		quotient[shift] = mod7(quotient[shift] + factor);
		for (usz degree = 0; degree <= denominator_degree; ++degree)
			remainder[shift + degree] = mod7(
				remainder[shift + degree] - factor * denominator[degree]);
		remainder_degree = poly_degree(remainder);
	}
	return true;
}

fn void multiply_poly(long* left, long* right, long* product) {
	for (usz degree = 0; degree < POLY; ++degree) product[degree] = 0;
	for (usz i = 0; i < POLY; ++i)
		for (usz j = 0; j < POLY && i + j < POLY; ++j)
			product[i + j] = mod7(product[i + j] + left[i] * right[j]);
}

fn void subtract_poly(long* result, long* left, long* right) {
	for (usz degree = 0; degree < POLY; ++degree)
		result[degree] = mod7(left[degree] - right[degree]);
}

fn long decode(usz n, usz k, usz errors, long* received) {
	long[POLY] interpolant = {};
	interpolate(n, received, &interpolant[0]);
	if (poly_zero(&interpolant[0])) return 1;

	long[POLY] r0 = {}, r1 = {};
	build_vanishing(n, &r0[0]);
	poly_copy(&r1[0], &interpolant[0]);
	long[POLY] v0 = {}, v1 = {1};
	long[POLY] candidate_numerator = {}, candidate_denominator = {};
	bool found = false;
	while (!poly_zero(&r1[0])) {
		if (2 * poly_degree(&r1[0]) < n + k) {
			poly_copy(&candidate_numerator[0], &r1[0]);
			poly_copy(&candidate_denominator[0], &v1[0]);
			found = true;
			break;
		}
		long[POLY] quotient = {}, remainder = {};
		if (!divide_poly(&r0[0], &r1[0], &quotient[0], &remainder[0])) return 0;
		if (poly_zero(&remainder[0])) break;
		long[POLY] product = {}, v2 = {};
		multiply_poly(&quotient[0], &v1[0], &product[0]);
		subtract_poly(&v2[0], &v0[0], &product[0]);
		poly_copy(&r0[0], &r1[0]);
		poly_copy(&r1[0], &remainder[0]);
		poly_copy(&v0[0], &v1[0]);
		poly_copy(&v1[0], &v2[0]);
	}
	if (!found || poly_zero(&candidate_denominator[0])) return 0;

	long[POLY] coefficients = {}, remainder = {};
	if (!divide_poly(&candidate_numerator[0], &candidate_denominator[0],
			&coefficients[0], &remainder[0]) || !poly_zero(&remainder[0])
			|| poly_degree(&coefficients[0]) >= k) return 0;
	usz mismatches = 0;
	for (usz x = 0; x < n; ++x) {
		long value = 0;
		for (usz degree = k; degree > 0; --degree)
			value = (value * (long)x + coefficients[degree - 1]) % 7;
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

fn long gao_rs_decode(long* input, usz length) @export("gao_rs_decode") {
	if (input == null || length < 3 || length > 11) return -1;
	long n_value = input[0], k_value = input[1], t_value = input[2];
	if (n_value < 2 || n_value > (long)MAX_N || k_value < 1 || k_value > (long)MAX_K
			|| k_value > n_value || t_value < 0 || t_value > 2
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
