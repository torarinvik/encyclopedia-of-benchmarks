// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
module number_theoretic_transform

const modulus = i64(998244353)

fn mod_pow(a_value i64, exponent_value i64) i64 {
	mut a := a_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * a % modulus }
		a = a * a % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'number_theoretic_transform']
pub fn number_theoretic_transform(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 65 { return -1 }
		n0 := input[0]
		if n0 < 1 || n0 > 64 || n0 & (n0 - 1) != 0 || input_length != usize(n0 + 1) { return -1 }
		n := int(n0)
		mut a := [64]i64{}
		for i in 0 .. n { if input[i+1] < 0 || input[i+1] >= modulus { return -1 }; a[i] = input[i+1] }
		if output == nil || output_capacity < usize(4*n) { return -2 }
		mut j := 0
		for i in 1 .. n {
			mut bit := n >> 1
			for j & bit != 0 { j ^= bit; bit >>= 1 }
			j ^= bit
			if i < j { a[i], a[j] = a[j], a[i] }
		}
		mut length := 2
		for length <= n {
			step := mod_pow(3, (modulus - 1) / i64(length))
			mut base := 0
			for base < n {
				mut w := i64(1)
				for k in 0 .. length / 2 {
					u := a[base+k]
					v := a[base+k+length/2] * w % modulus
					a[base+k] = (u + v) % modulus
					a[base+k+length/2] = (u - v + modulus) % modulus
					w = w * step % modulus
				}
				base += length
			}
			length *= 2
		}
		for i in 0 .. n { x := u32(a[i]); for b in 0 .. 4 { output[4*i+b] = u8(x >> (8*b)) } }
		return i64(4*n)
	}
}
