/* Clean-room bounded CFRAC profile based on the published
   Morrison-Brillhart continued-fraction factorization method.
   No code from the restricted arbitrary-precision package is included. */
package mallocbench_cfrac

import "core:c"

MAX_BASE :: 10
MAX_ITERATIONS :: 48
MAX_PRIME :: 10000

gcd :: proc "contextless" (a_value, b_value: u64) -> u64 {
	a, b := a_value, b_value
	for b != 0 { r := a % b; a, b = b, r }
	return a
}

modpow :: proc "contextless" (base_value, exponent_value, modulus: u64) -> u64 {
	base, exponent, result := base_value % modulus, exponent_value, u64(1)
	for exponent != 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

is_prime :: proc "contextless" (value: u32) -> bool {
	if value < 2 do return false
	for divisor := u32(2); u64(divisor) * u64(divisor) <= u64(value); divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

make_base :: proc "contextless" (n: u64, requested: int, base: [^]u32) -> bool {
	count := 1
	base[0] = 2
	for p := 3; p <= MAX_PRIME && count < requested; p += 2 {
		if !is_prime(u32(p)) do continue
		residue := modpow(n % u64(p), u64((p - 1) / 2), u64(p))
		// Upstream selects residue zero too; this bounded profile rejects it.
		if residue == 0 do return false
		if residue == 1 {
			base[count] = u32(p)
			count += 1
		}
	}
	return count == requested
}

@(export)
mallocbench_cfrac :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	n_value, base_value, iteration_value := input[0], input[1], input[2]
	if n_value < 15 || n_value > 1000000 || (n_value & 1) == 0 ||
		base_value < 2 || base_value > MAX_BASE || iteration_value < 1 || iteration_value > MAX_ITERATIONS do return -1
	n := u64(n_value)
	root := u64(0)
	for root + 1 <= n / (root + 1) { root += 1 }
	if root * root == n do return -1
	base_count, iteration_limit := int(base_value), int(iteration_value)
	base: [MAX_BASE]u32
	if !make_base(n, base_count, &base[0]) do return -1

	basis_vector: [MAX_BASE + 1]u64
	basis_combo: [MAX_BASE + 1]u64
	basis_used: [MAX_BASE + 1]bool
	relation_a: [MAX_ITERATIONS]u64
	relation_exp: [MAX_ITERATIONS][MAX_BASE]u8
	relation_count := 0
	u, previous_u := i64(2 * root), i64(2 * root)
	q_value, q_denominator := i64(0), i64(1)
	previous_denominator := i64(n - root * root)
	a_value, previous_a := i64(1), i64(root)
	sign := u64(0)

	for iteration := 0; iteration < iteration_limit; iteration += 1 {
		old_a := a_value
		a_value = (q_value * a_value + previous_a) % n_value
		previous_a = old_a
		old_denominator := q_denominator
		q_denominator = q_value * (previous_u - u) + previous_denominator
		previous_denominator = old_denominator
		previous_u = u
		if q_denominator <= 0 do return i64(n)
		q_value = 1
		remainder := u - q_denominator
		if remainder >= q_denominator { q_value = u / q_denominator; remainder = u % q_denominator }
		u = i64(2 * root) - remainder
		sign ^= 1
		if q_denominator == 1 do return i64(n)

		residual := u64(q_denominator)
		exponents: [MAX_BASE]u8
		for j := 0; j < base_count; j += 1 {
			for residual % u64(base[j]) == 0 { residual /= u64(base[j]); exponents[j] += 1 }
		}
		if residual != 1 do continue
		relation_a[relation_count] = u64(a_value)
		for j := 0; j < base_count; j += 1 { relation_exp[relation_count][j] = exponents[j] }
		vector := sign
		for j := 0; j < base_count; j += 1 { if (exponents[j] & 1) != 0 { vector |= u64(1) << (j + 1) } }
		combination := u64(1) << relation_count
		relation_count += 1
		inserted := false
		for bit := 0; bit <= base_count; bit += 1 {
			if (vector & (u64(1) << bit)) == 0 do continue
			if basis_used[bit] {
				vector ^= basis_vector[bit]
				combination ^= basis_combo[bit]
			} else {
				basis_used[bit] = true
				basis_vector[bit] = vector
				basis_combo[bit] = combination
				inserted = true
				break
			}
		}
		if !inserted {
			x := u64(1)
			exponent_sum: [MAX_BASE]u64
			for i := 0; i < relation_count; i += 1 {
				if (combination & (u64(1) << i)) == 0 do continue
				x = (x * relation_a[i]) % n
				for j := 0; j < base_count; j += 1 { exponent_sum[j] += u64(relation_exp[i][j]) }
			}
			y := u64(1)
			for j := 0; j < base_count; j += 1 { y = (y * modpow(u64(base[j]), exponent_sum[j] / 2, n)) % n }
			minus := gcd(x >= y ? x - y : y - x, n)
			if minus > 1 && minus < n do return i64(minus)
			plus := gcd(x + y, n)
			if plus > 1 && plus < n do return i64(plus)
		}
	}
	return n_value
}
