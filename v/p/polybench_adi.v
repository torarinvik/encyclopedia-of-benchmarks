module main

import math

const max_dimension = 32
const max_cells = max_dimension * max_dimension
const max_tsteps = i64(20)

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polybench_adi']
pub fn polybench_adi(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 || input[0] < 1 || input[0] > i64(max_dimension) ||
			input[1] < 1 || input[1] > max_tsteps { return -1 }
		n := int(input[0])
		tsteps := int(input[1])
		cells := n * n
		output_bytes := cells * 8
		if output == nil || usize(output_bytes) > output_capacity { return -2 }

		mut u := [max_cells]f64{}
		mut v := [max_cells]f64{}
		mut p := [max_cells]f64{}
		mut q := [max_cells]f64{}
		for i := 0; i < n; i++ {
			for j := 0; j < n; j++ {
				u[i * n + j] = f64(i + n - j) / f64(n)
			}
		}

		dx := 1.0 / f64(n)
		dy := 1.0 / f64(n)
		dt := 1.0 / f64(tsteps)
		b1 := 2.0
		b2 := 1.0
		mul1 := b1 * dt / (dx * dx)
		mul2 := b2 * dt / (dy * dy)
		a := -mul1 / 2.0
		b := 1.0 + mul1
		c := a
		d := -mul2 / 2.0
		e := 1.0 + mul2
		f := d

		for _ in 0 .. tsteps {
			for i := 1; i < n - 1; i++ {
				v[i] = 1.0
				p[i * n] = 0.0
				q[i * n] = v[i]
				for j := 1; j < n - 1; j++ {
					p[i * n + j] = -c / (a * p[i * n + j - 1] + b)
					q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
								- f * u[j * n + i + 1] - a * q[i * n + j - 1]) /
							   (a * p[i * n + j - 1] + b)
				}
				v[(n - 1) * n + i] = 1.0
				mut j := n - 1
				for j > 1 {
					j--
					v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j]
				}
			}

			for i := 1; i < n - 1; i++ {
				u[i * n] = 1.0
				p[i * n] = 0.0
				q[i * n] = u[i * n]
				for j := 1; j < n - 1; j++ {
					p[i * n + j] = -f / (d * p[i * n + j - 1] + e)
					q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
								- c * v[(i + 1) * n + j] - d * q[i * n + j - 1]) /
							   (d * p[i * n + j - 1] + e)
				}
				u[i * n + n - 1] = 1.0
				mut j := n - 1
				for j > 1 {
					j--
					u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j]
				}
			}
		}

		for index in 0 .. cells { write_f64_le(mut output, index * 8, u[index]) }
		return i64(output_bytes)
	}
}
