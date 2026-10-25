module tsvc_s258_wrapped_scalar_expansion

const max_n = 64
const max_input_length = 257

@[export: 'tsvc_s258_wrapped_scalar_expansion']
pub fn tsvc_s258_wrapped_scalar_expansion(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 4 * n { return -1 }
		mut a := [max_n]i64{}
		mut c := [max_n]i64{}
		mut d := [max_n]i64{}
		mut aa0 := [max_n]i64{}
		mut b := [max_n]i64{}
		mut e := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[1 + i]
			c[i] = input[1 + n + i]
			d[i] = input[1 + 2 * n + i]
			aa0[i] = input[1 + 3 * n + i]
			if a[i] < 0 || a[i] > 2 || c[i] < 0 || c[i] > 2 ||
				d[i] < 0 || d[i] > 2 || aa0[i] < 0 || aa0[i] > 2 { return -1 }
		}
		mut s := i64(0)
		for i in 0 .. n {
			if a[i] > 0 { s = d[i] * d[i] }
			b[i] = s * c[i] + d[i]
			e[i] = (s + 1) * aa0[i]
		}
		mut sum_b := i64(0)
		mut sum_e := i64(0)
		for i in 0 .. n {
			sum_b += b[i]
			sum_e += e[i]
		}
		return sum_b + sum_e
	}
}
