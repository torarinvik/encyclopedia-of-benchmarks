package polybench_adi

import "core:c"

MAX_DIMENSION :: 32
MAX_CELLS :: MAX_DIMENSION * MAX_DIMENSION
MAX_TSTEPS :: 20

write_f64_le :: proc "contextless"(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
polybench_adi :: proc "c" (values: [^]i64, length: c.size_t,
							 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
		values[1] < 1 || values[1] > MAX_TSTEPS do return -1
	n := int(values[0])
	tsteps := int(values[1])
	cells := n * n
	output_bytes := cells * 8
	if output == nil || c.size_t(output_bytes) > output_capacity do return -2

	u: [MAX_CELLS]f64 = {}
	v: [MAX_CELLS]f64 = {}
	p: [MAX_CELLS]f64 = {}
	q: [MAX_CELLS]f64 = {}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
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
	c_value := a
	d := -mul2 / 2.0
	e := 1.0 + mul2
	f := d

	for _t := 0; _t < tsteps; _t += 1 {
		for i := 1; i < n - 1; i += 1 {
			v[i] = 1.0
			p[i * n] = 0.0
			q[i * n] = v[i]
			for j := 1; j < n - 1; j += 1 {
				p[i * n + j] = -c_value / (a * p[i * n + j - 1] + b)
				q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
								- f * u[j * n + i + 1] - a * q[i * n + j - 1]) /
							   (a * p[i * n + j - 1] + b)
			}
			v[(n - 1) * n + i] = 1.0
			j := n - 1
			for j > 1 {
				j -= 1
				v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j]
			}
		}

		for i := 1; i < n - 1; i += 1 {
			u[i * n] = 1.0
			p[i * n] = 0.0
			q[i * n] = u[i * n]
			for j := 1; j < n - 1; j += 1 {
				p[i * n + j] = -f / (d * p[i * n + j - 1] + e)
				q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
								- c_value * v[(i + 1) * n + j] - d * q[i * n + j - 1]) /
							   (d * p[i * n + j - 1] + e)
			}
			u[i * n + n - 1] = 1.0
			j := n - 1
			for j > 1 {
				j -= 1
				u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j]
			}
		}
	}

	for index := 0; index < cells; index += 1 {
		write_f64_le(output, index * 8, u[index])
	}
	return i64(output_bytes)
}
