module inv_of_polynomials

const modulus = i64(998244353)
const max_length = 6
const max_input = 14
const poly_capacity = 16

fn power_mod(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn trim(poly [poly_capacity]i64, length_input int) int {
	mut length := length_input
	for length > 0 && poly[length - 1] == 0 { length-- }
	return length
}

fn divide_poly(dividend [poly_capacity]i64, dividend_length int,
		divisor [poly_capacity]i64, divisor_length int) ([poly_capacity]i64, int, [poly_capacity]i64, int) {
	mut quotient := [poly_capacity]i64{}
	mut remainder := [poly_capacity]i64{}
	for i in 0 .. dividend_length { remainder[i] = dividend[i] }
	mut remainder_length := trim(remainder, dividend_length)
	if remainder_length >= divisor_length {
		inverse_lead := power_mod(divisor[divisor_length - 1], modulus - 2)
		for remainder_length >= divisor_length {
			shift := remainder_length - divisor_length
			factor := remainder[remainder_length - 1] * inverse_lead % modulus
			quotient[shift] = factor
			for j in 0 .. divisor_length {
				mut value := (remainder[shift + j] - factor * divisor[j]) % modulus
				if value < 0 { value += modulus }
				remainder[shift + j] = value
			}
			remainder_length = trim(remainder, remainder_length)
		}
	}
	quotient_bound := if dividend_length >= divisor_length { dividend_length - divisor_length + 1 } else { 0 }
	quotient_length := trim(quotient, quotient_bound)
	return quotient, quotient_length, remainder, remainder_length
}

fn multiply_poly(left [poly_capacity]i64, left_length int,
		right [poly_capacity]i64, right_length int) ([poly_capacity]i64, int) {
	mut product := [poly_capacity]i64{}
	if left_length == 0 || right_length == 0 { return product, 0 }
	for i in 0 .. left_length {
		for j in 0 .. right_length {
			if i + j < poly_capacity {
				product[i + j] = (product[i + j] + left[i] * right[j]) % modulus
			}
		}
	}
	mut bound := left_length + right_length - 1
	if bound > poly_capacity { bound = poly_capacity }
	return product, trim(product, bound)
}

fn subtract_poly(left [poly_capacity]i64, left_length int,
		right [poly_capacity]i64, right_length int) ([poly_capacity]i64, int) {
	mut difference := [poly_capacity]i64{}
	bound := if left_length > right_length { left_length } else { right_length }
	for i in 0 .. bound {
		a := if i < left_length { left[i] } else { i64(0) }
		b := if i < right_length { right[i] } else { i64(0) }
		difference[i] = (a - b + modulus) % modulus
	}
	return difference, trim(difference, bound)
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'inv_of_polynomials']
pub fn inv_of_polynomials(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_length || input[1] < 1 || input[1] > max_length { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		mut f := [poly_capacity]i64{}
		mut g := [poly_capacity]i64{}
		for i in 0 .. n {
			f[i] = input[2 + i]
			if f[i] < 0 || f[i] >= modulus { return -1 }
		}
		for i in 0 .. m {
			g[i] = input[2 + n + i]
			if g[i] < 0 || g[i] >= modulus { return -1 }
		}
		if f[n - 1] == 0 || g[m - 1] == 0 { return -1 }

		mut inverse := [poly_capacity]i64{}
		mut inverse_length := 0
		if m > 1 {
			_, _, initial_remainder, initial_remainder_length := divide_poly(f, n, g, m)
			mut r1 := initial_remainder
			mut r1_length := initial_remainder_length
			mut r0 := g
			mut s0 := [poly_capacity]i64{}
			mut s1 := [poly_capacity]i64{}
			s1[0] = 1
			mut r0_length := m
			mut s0_length := 0
			mut s1_length := 1
			for r1_length > 0 {
				quotient, quotient_length, remainder, remainder_length := divide_poly(r0, r0_length, r1, r1_length)
				product, product_length := multiply_poly(quotient, quotient_length, s1, s1_length)
				next_s, next_s_length := subtract_poly(s0, s0_length, product, product_length)
				r0 = r1
				r1 = remainder
				r0_length = r1_length
				r1_length = remainder_length
				s0 = s1
				s1 = next_s
				s0_length = s1_length
				s1_length = next_s_length
			}
			if r0_length != 1 { return -1 }
			scale := power_mod(r0[0], modulus - 2)
			for i in 0 .. s0_length { inverse[i] = s0[i] * scale % modulus }
			inverse_length = trim(inverse, s0_length)
			_, _, reduced, reduced_length := divide_poly(inverse, inverse_length, g, m)
			inverse = reduced
			inverse_length = reduced_length
		}
		bytes := 8 * inverse_length
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. inverse_length { store_le(mut output, 8 * i, inverse[i]) }
		return i64(bytes)
	}
}
