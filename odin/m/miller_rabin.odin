package miller_rabin

// Deterministic Miller-Rabin for signed 32-bit inputs.
mod_power :: proc "contextless" (base_value, exponent_value, modulus: i64) -> i64 {
	base := base_value % modulus
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 do result = (result * base) % modulus
		base = (base * base) % modulus
		exponent /= 2
	}
	return result
}

passes_base :: proc "contextless" (n, base, odd_part, powers_of_two: i64) -> bool {
	value := mod_power(base, odd_part, n)
	if value == 1 || value == n - 1 do return true
	for round := i64(1); round < powers_of_two; round += 1 {
		value = (value * value) % n
		if value == n - 1 do return true
	}
	return false
}

@(export)
miller_rabin :: proc "c" (n: i64) -> i64 {
	if n < 2 do return 0
	if n > 2147483647 do return -1
	if n == 2 || n == 3 || n == 5 || n == 7 do return 1
	if n % 2 == 0 || n % 3 == 0 || n % 5 == 0 || n % 7 == 0 do return 0

	odd_part := n - 1
	powers_of_two := i64(0)
	for odd_part % 2 == 0 {
		odd_part /= 2
		powers_of_two += 1
	}
	if !passes_base(n, 2, odd_part, powers_of_two) do return 0
	if !passes_base(n, 3, odd_part, powers_of_two) do return 0
	if !passes_base(n, 5, odd_part, powers_of_two) do return 0
	if !passes_base(n, 7, odd_part, powers_of_two) do return 0
	return 1
}
