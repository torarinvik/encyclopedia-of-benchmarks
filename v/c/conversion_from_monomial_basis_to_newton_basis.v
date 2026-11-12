module conversion_from_monomial_basis_to_newton_basis

const modulus = i64(998244353)
const max_n = 12
const max_input = 25

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'conversion_from_monomial_basis_to_newton_basis']
pub fn conversion_from_monomial_basis_to_newton_basis(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 2 * n) { return -1 }
		for i in 0 .. 2 * n {
			if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 }
		}
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut residual := [max_n]i64{}
		mut answer := [max_n]i64{}
		for i in 0 .. n { residual[i] = input[i + 1] }
		mut active := n
		for i in 0 .. n {
			node := input[n + 1 + i]
			mut value := i64(0)
			for degree := active; degree > 0; degree-- {
				value = (value * node + residual[degree - 1]) % modulus
			}
			answer[i] = value
			if active == 1 { continue }
			mut quotient := [max_n]i64{}
			quotient[active - 2] = residual[active - 1]
			for degree := active - 2; degree > 0; degree-- {
				quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % modulus
			}
			for degree in 0 .. active - 1 { residual[degree] = quotient[degree] }
			active--
		}
		for i in 0 .. n { store_le(mut output, 8 * i, answer[i]) }
		return i64(bytes)
	}
}
