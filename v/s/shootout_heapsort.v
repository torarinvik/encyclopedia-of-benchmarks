const max_length = 8192
const output_bytes = 9
const modulus = i64(139968)
const multiplier = i64(3877)
const increment = i64(29573)

fn source_heapsort(n int, mut values []f64) {
	mut ir := n
	mut l := (n / 2) + 1
	for {
		mut rra := f64(0)
		if l > 1 {
			l -= 1
			rra = values[l]
		} else {
			rra = values[ir]
			values[ir] = values[1]
			ir -= 1
			if ir == 1 {
				values[1] = rra
				return
			}
		}
		mut i := l
		mut j := l * 2
		for j <= ir {
			if j < ir && values[j] < values[j + 1] { j += 1 }
			if rra < values[j] {
				values[i] = values[j]
				i = j
				j += i
			} else {
				j = ir + 1
			}
		}
		values[i] = rra
	}
}

fn write_fixed_six(mut output &u8, value f64) {
	millionths := u32(value * 1_000_000.0 + 0.5)
	whole := millionths / 1_000_000
	mut fraction := millionths % 1_000_000
	unsafe {
		output[0] = u8(48 + whole)
		output[1] = 46
		mut divisor := u32(100_000)
		for index in 2 .. 8 {
			output[index] = u8(48 + (fraction / divisor) % 10)
			divisor /= 10
		}
		output[8] = 10
	}
}

@[export: 'shootout_heapsort']
pub fn shootout_heapsort(length i64, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_length { return -1 }
	if unsafe { output == nil } || output_capacity < output_bytes { return -2 }

	mut values := [max_length + 1]f64{}
	mut state := i64(42)
	for index in 1 .. int(length) + 1 {
		state = (state * multiplier + increment) % modulus
		values[index] = 1.0 * f64(state) / f64(modulus)
	}
	unsafe {
		source_heapsort(int(length), mut values[..])
		write_fixed_six(mut output, values[int(length)])
	}
	return output_bytes
}
