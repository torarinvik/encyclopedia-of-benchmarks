module mul_modp_convolution

const max_p = 97
const max_input = 196
const max_output = 776
const mod = i64(998244353)

fn pow_mod(base_input i64, exponent_input int, modulus int) int {
	mut base := base_input % i64(modulus)
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % i64(modulus) }
		base = base * base % i64(modulus)
		exponent >>= 1
	}
	return int(result)
}

fn is_prime(p int) bool {
	if p < 2 { return false }
	for d in 2 .. p { if d*d > p { break }; if p%d == 0 { return false } }
	return true
}

fn primitive_root(p int) int {
	order := p-1
	for candidate in 1 .. p {
		mut good := true
		for factor in 2 .. order+1 {
			if order%factor != 0 || !is_prime(factor) { continue }
			if pow_mod(i64(candidate),order/factor,p) == 1 { good=false; break }
		}
		if good { return candidate }
	}
	return 1
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits&255) }; bits >>= 8 }
}

@[export: 'mul_modp_convolution']
pub fn mul_modp_convolution(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		p0 := input[0]
		if p0 < 2 || p0 > max_p || !is_prime(int(p0)) { return -1 }
		p := int(p0)
		if length != usize(1+2*p) { return -1 }
		for i in 1 .. int(length) { if input[i] < 0 || input[i] >= mod { return -1 } }
		bytes := 8*p
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut a := []i64{len:max_p,init:0}; mut b := []i64{len:max_p,init:0}
		mut left := []i64{len:max_p,init:0}; mut right := []i64{len:max_p,init:0}
		mut cyclic := []i64{len:max_p,init:0}; mut result := []i64{len:max_p,init:0}
		mut by_exp := []int{len:max_p,init:0}
		for i in 0 .. p { a[i]=input[1+i]; b[i]=input[1+p+i] }
		q := p-1; root := primitive_root(p); mut residue := 1
		for e in 0 .. q { by_exp[e]=residue; residue=residue*root%p }
		for e in 0 .. q { left[e]=a[by_exp[e]]; right[e]=b[by_exp[e]] }
		for i in 0 .. q { for j in 0 .. q { slot:=(i+j)%q; cyclic[slot]=(cyclic[slot]+left[i]*right[j]%mod)%mod } }
		mut sum_a := i64(0); mut sum_b := i64(0)
		for i in 0 .. p { sum_a=(sum_a+a[i])%mod }
		for i in 1 .. p { sum_b=(sum_b+b[i])%mod }
		result[0]=(sum_a*b[0]%mod+a[0]*sum_b%mod)%mod
		for e in 0 .. q { result[by_exp[e]]=cyclic[e] }
		for i in 0 .. p { store_le(mut output,8*i,result[i]) }
		return i64(bytes)
	}
}
