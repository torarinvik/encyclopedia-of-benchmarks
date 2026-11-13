module dirichlet_convolution_and_prefix_sums

const max_n = 64
const max_q = 15
const max_parseable = 32
const modulus = i64(998244353)

fn prefix_value(q []i64, prefix []i64, count int, value i64) i64 {
	if value == 0 { return 0 }
	for i in 0 .. count {
		if q[i] == value { return prefix[i] }
	}
	return 0
}

fn store_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'dirichlet_convolution_and_prefix_sums']
pub fn dirichlet_convolution_and_prefix_sums(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_parseable { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := input[0]
		mut descending := []i64{len: max_q}
		mut count := 0
		mut left := i64(1)
		for left <= n {
			value := n / left
			descending[count] = value
			count++
			left = n / value + 1
		}
		mut q := []i64{len: max_q}
		for i in 0 .. count { q[i] = descending[count - 1 - i] }
		if length != usize(1 + 2 * count) { return -1 }
		mut f := []i64{len: max_q}
		mut g := []i64{len: max_q}
		mut result := []i64{len: max_q}
		for i in 0 .. count {
			f[i] = input[1 + i]
			g[i] = input[1 + count + i]
			if f[i] < 1 || f[i] >= modulus || g[i] < 1 || g[i] >= modulus { return -1 }
		}
		needed := 8 * count
		if output == nil || output_capacity < usize(needed) { return -2 }

		for out_index in 0 .. count {
			x := q[out_index]
			mut total := i64(0)
			mut start := i64(1)
			for start <= x {
				quotient := x / start
				right := x / quotient
				below := x / (quotient + 1)
				mut interval := (prefix_value(q, f, count, right) -
					prefix_value(q, f, count, below)) % modulus
				if interval < 0 { interval += modulus }
				mut q_index := 0
				for q_index < count && q[q_index] != quotient { q_index++ }
				if q_index == count { return -1 }
				total = (total + interval * g[q_index]) % modulus
				start = right + 1
			}
			result[out_index] = total
		}
		for i in 0 .. count {
			store_le(unsafe { &output[8 * i] }, result[i])
		}
		return i64(needed)
	}
}
