module min_plus_convolution_convex_convex

const max_input = 259
const max_output = 2040
const max_n = 128
const max_m = 128

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'min_plus_convolution_convex_convex']
pub fn min_plus_convolution_convex_convex(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n0 := input[0]
		m0 := input[1]
		if n0 < 1 || n0 > max_n || m0 < 1 || m0 > max_m { return -1 }
		n := int(n0)
		m := int(m0)
		if length != usize(2 + n + m) { return -1 }
		mut a := []i64{len: max_n, init: 0}
		mut b := []i64{len: max_m, init: 0}
		for i in 0 .. n + m {
			value := input[2 + i]
			if value < 0 || value > 1_000_000_000 { return -1 }
			if i < n { a[i] = value } else { b[i - n] = value }
		}
		for i in 0 .. n {
			if i + 2 < n && a[i + 1] - a[i] > a[i + 2] - a[i + 1] { return -1 }
		}
		for i in 0 .. m {
			if i + 2 < m && b[i + 1] - b[i] > b[i + 2] - b[i + 1] { return -1 }
		}
		count := n + m - 1
		bytes := 8 * count
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut result := []i64{len: max_n + max_m - 1, init: 0}
		result[0] = a[0] + b[0]
		mut ai := 0
		mut bi := 0
		mut out := 1
		for ai + 1 < n || bi + 1 < m {
			mut slope := i64(0)
			if bi + 1 == m || (ai + 1 < n && a[ai + 1] - a[ai] <= b[bi + 1] - b[bi]) {
				slope = a[ai + 1] - a[ai]
				ai++
			} else {
				slope = b[bi + 1] - b[bi]
				bi++
			}
			result[out] = result[out - 1] + slope
			out++
		}
		for i in 0 .. count { store_i64_le(mut output, 8 * i, result[i]) }
		return i64(bytes)
	}
}
