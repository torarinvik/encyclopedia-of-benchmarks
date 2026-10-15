module miller_rabin

// Deterministic Miller-Rabin for signed 32-bit inputs.
fn mod_power(base_value i64, exponent_value i64, modulus i64) i64 {
	mut base := base_value % modulus
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent /= 2
	}
	return result
}

fn passes_base(n i64, base i64, odd_part i64, powers_of_two i64) bool {
	mut value := mod_power(base, odd_part, n)
	if value == 1 || value == n - 1 { return true }
	for _ in 1 .. powers_of_two {
		value = (value * value) % n
		if value == n - 1 { return true }
	}
	return false
}

@[export: 'miller_rabin']
pub fn miller_rabin(n i64) i64 {
	if n < 2 { return 0 }
	if n > 2147483647 { return -1 }
	for prime in [i64(2), 3, 5, 7] {
		if n == prime { return 1 }
		if n % prime == 0 { return 0 }
	}

	mut odd_part := n - 1
	mut powers_of_two := i64(0)
	for odd_part % 2 == 0 {
		odd_part /= 2
		powers_of_two += 1
	}
	for base in [i64(2), 3, 5, 7] {
		if !passes_base(n, base, odd_part, powers_of_two) { return 0 }
	}
	return 1
}
