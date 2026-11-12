const MAX_VALUE: i64 = 1_000_000_000;

fn totient(value: i64) i64 {
	var result = value;
	var remaining = value;
	if (@rem(remaining, 2) == 0) {
		result -= @divTrunc(result, 2);
		while (@rem(remaining, 2) == 0) remaining = @divTrunc(remaining, 2);
	}
	var factor: i64 = 3;
	while (factor <= @divTrunc(remaining, factor)) : (factor += 2) {
		if (@rem(remaining, factor) == 0) {
			result -= @divTrunc(result, factor);
			while (@rem(remaining, factor) == 0) remaining = @divTrunc(remaining, factor);
		}
	}
	if (remaining > 1) result -= @divTrunc(result, remaining);
	return result;
}

fn powerCapped(base: i64, exponent_input: i64, cap: i64) i64 {
	var result: i64 = 1;
	var factor = @min(base, cap);
	var exponent = exponent_input;
	while (exponent > 0) {
		if (@rem(exponent, 2) != 0) {
			result *= factor;
			if (result >= cap) return cap;
		}
		exponent = @divTrunc(exponent, 2);
		if (exponent > 0) {
			factor *= factor;
			if (factor >= cap) factor = cap;
		}
	}
	return result;
}

fn towerCapped(base: i64, height_input: i64, cap: i64) i64 {
	if (height_input == 0) return @min(@as(i64, 1), cap);
	if (base == 0) return if (@rem(height_input, 2) == 0) 1 else 0;
	if (base == 1) return @min(@as(i64, 1), cap);
	var value: i64 = 1;
	if (value >= cap) return cap;
	var height = height_input;
	while (height > 0) {
		value = powerCapped(base, value, cap);
		if (value >= cap) return cap;
		height -= 1;
	}
	return value;
}

fn modularPower(base_input: i64, exponent_input: i64, modulus: i64) i64 {
	var result: i64 = @rem(1, modulus);
	var base = @rem(base_input, modulus);
	var exponent = exponent_input;
	while (exponent > 0) {
		if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
		exponent = @divTrunc(exponent, 2);
		base = @rem(base * base, modulus);
	}
	return result;
}

fn tetration(base: i64, height: i64, modulus: i64) i64 {
	if (modulus == 1) return 0;
	if (height == 0) return @rem(1, modulus);
	if (height == 1) return @rem(base, modulus);
	const exponent_modulus = totient(modulus);
	var exponent = tetration(base, height - 1, exponent_modulus);
	if (towerCapped(base, height - 1, exponent_modulus) >= exponent_modulus) {
		exponent += exponent_modulus;
	}
	return modularPower(base, exponent, modulus);
}

/// Packed input [A, B, M], where B is the power-tower height.
export fn tetration_mod(values: [*c]const i64, length: usize) i64 {
	if (values == null or length != 3) return -1;
	const base = values[0];
	const height = values[1];
	const modulus = values[2];
	if (base < 0 or base > MAX_VALUE or height < 0 or height > MAX_VALUE or
		modulus < 1 or modulus > MAX_VALUE) return -1;
	return tetration(base, height, modulus);
}
