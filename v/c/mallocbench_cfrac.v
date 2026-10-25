/* Clean-room bounded CFRAC profile based on the published
   Morrison-Brillhart continued-fraction factorization method.
   No code from the restricted arbitrary-precision package is included. */
module mallocbench_cfrac

const max_base = 10
const max_iterations = 48
const max_prime = 10000

fn gcd(a_value u64, b_value u64) u64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		r := a % b
		a = b
		b = r
	}
	return a
}

fn modpow(base_value u64, exponent_value u64, modulus u64) u64 {
	mut base := base_value % modulus
	mut exponent := exponent_value
	mut result := u64(1)
	for exponent != 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn is_prime(value u32) bool {
	if value < 2 { return false }
	mut divisor := u32(2)
	for u64(divisor) * u64(divisor) <= u64(value) {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn make_base(n u64, requested int, mut base [max_base]u32) bool {
	mut count := 1
	base[0] = 2
	mut p := 3
	for p <= max_prime && count < requested {
		if is_prime(u32(p)) {
			residue := modpow(n % u64(p), u64((p - 1) / 2), u64(p))
			// Upstream selects residue zero too; this bounded profile rejects it.
			if residue == 0 { return false }
			if residue == 1 {
				base[count] = u32(p)
				count++
			}
		}
		p += 2
	}
	return count == requested
}

@[export: 'mallocbench_cfrac']
pub fn mallocbench_cfrac(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		n_value, base_value, iteration_value := input[0], input[1], input[2]
		if n_value < 15 || n_value > 1000000 || (n_value & 1) == 0 ||
			base_value < 2 || base_value > max_base || iteration_value < 1 || iteration_value > max_iterations { return -1 }
		n := u64(n_value)
		mut root := u64(0)
		for root + 1 <= n / (root + 1) { root++ }
		if root * root == n { return -1 }
		base_count, iteration_limit := int(base_value), int(iteration_value)
		mut base := [max_base]u32{}
		if !make_base(n, base_count, mut base) { return -1 }

		mut basis_vector := [max_base + 1]u64{}
		mut basis_combo := [max_base + 1]u64{}
		mut basis_used := [max_base + 1]bool{}
		mut relation_a := [max_iterations]u64{}
		mut relation_exp := [max_iterations][max_base]u8{}
		mut relation_count := 0
		mut u := i64(2 * root)
		mut previous_u := u
		mut q_value := i64(0)
		mut q_denominator := i64(1)
		mut previous_denominator := i64(n - root * root)
		mut a_value := i64(1)
		mut previous_a := i64(root)
		mut sign := u64(0)

		for _ in 0 .. iteration_limit {
			old_a := a_value
			a_value = (q_value * a_value + previous_a) % n_value
			previous_a = old_a
			old_denominator := q_denominator
			q_denominator = q_value * (previous_u - u) + previous_denominator
			previous_denominator = old_denominator
			previous_u = u
			if q_denominator <= 0 { return i64(n) }
			q_value = 1
			mut remainder := u - q_denominator
			if remainder >= q_denominator {
				q_value = u / q_denominator
				remainder = u % q_denominator
			}
			u = i64(2 * root) - remainder
			sign ^= 1
			if q_denominator == 1 { return i64(n) }

			mut residual := u64(q_denominator)
			mut exponents := [max_base]u8{}
			for j in 0 .. base_count {
				for residual % u64(base[j]) == 0 {
					residual /= u64(base[j])
					exponents[j]++
				}
			}
			if residual != 1 { continue }
			relation_a[relation_count] = u64(a_value)
			for j in 0 .. base_count { relation_exp[relation_count][j] = exponents[j] }
			mut vector := sign
			for j in 0 .. base_count { if (exponents[j] & 1) != 0 { vector |= u64(1) << (j + 1) } }
			mut combination := u64(1) << relation_count
			relation_count++
			mut inserted := false
			for bit in 0 .. base_count + 1 {
				if (vector & (u64(1) << bit)) == 0 { continue }
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
				mut x := u64(1)
				mut exponent_sum := [max_base]u64{}
				for i in 0 .. relation_count {
					if (combination & (u64(1) << i)) == 0 { continue }
					x = (x * relation_a[i]) % n
					for j in 0 .. base_count { exponent_sum[j] += u64(relation_exp[i][j]) }
				}
				mut y := u64(1)
				for j in 0 .. base_count { y = (y * modpow(u64(base[j]), exponent_sum[j] / 2, n)) % n }
				minus := gcd(if x >= y { x - y } else { y - x }, n)
				if minus > 1 && minus < n { return i64(minus) }
				plus := gcd(x + y, n)
				if plus > 1 && plus < n { return i64(plus) }
			}
		}
		return n_value
	}
}
