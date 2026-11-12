module fluidanimate_sph

import math

const max_particles = 32
const max_input_length = 2 + 6 * max_particles
const pi_value = 3.14159265358979323846264338327950288

fn store_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'fluidanimate_sph']
pub fn fluidanimate_sph(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		count_value, rpm_milli := input[0], input[1]
		if count_value < 1 || count_value > max_particles || rpm_milli < 500 || rpm_milli > 5000 { return -1 }
		count := int(count_value)
		if int(length) != 2 + 6 * count { return -1 }
		for i in 0 .. count {
			base := 2 + 6 * i
			for axis in 0 .. 3 {
				if input[base + axis] < -10000 || input[base + axis] > 10000 { return -1 }
				if input[base + 3 + axis] < -5000 || input[base + 3 + axis] > 5000 { return -1 }
			}
		}
		output_bytes := 40 * count
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut position := [max_particles][3]f64{}
		mut velocity := [max_particles][3]f64{}
		mut acceleration := [max_particles][3]f64{}
		mut density := [max_particles]f64{}
		rpm := f64(rpm_milli) / 1000.0
		h := 1.695 / rpm
		h2 := h * h
		mass := 1000.0 / (rpm * rpm * rpm)
		density_coeff := mass * (315.0 / (64.0 * pi_value * math.pow(h, 9.0)))
		pressure_coeff := 3.0 * (15.0 / (pi_value * math.pow(h, 6.0))) * 1.5 * mass
		viscosity_coeff := 0.4 * (45.0 / (pi_value * math.pow(h, 6.0))) * mass
		for i in 0 .. count {
			base := 2 + 6 * i
			for axis in 0 .. 3 {
				position[i][axis] = f64(input[base + axis]) / 1000.0
				velocity[i][axis] = f64(input[base + 3 + axis]) / 1000.0
				acceleration[i][axis] = if axis == 1 { -9.8 } else { 0.0 }
			}
			density[i] = density_coeff * h2 * h2 * h2
		}
		for i in 0 .. count {
			for j in i + 1 .. count {
				dx := position[i][0] - position[j][0]
				dy := position[i][1] - position[j][1]
				dz := position[i][2] - position[j][2]
				r2 := dx * dx + dy * dy + dz * dz
				if r2 < h2 {
					term := density_coeff * math.pow(h2 - r2, 3.0)
					density[i] += term
					density[j] += term
				}
			}
		}
		for i in 0 .. count {
			for j in i + 1 .. count {
				disp := [3]f64{position[i][0] - position[j][0], position[i][1] - position[j][1], position[i][2] - position[j][2]}
				r2 := disp[0] * disp[0] + disp[1] * disp[1] + disp[2] * disp[2]
				if r2 >= h2 { continue }
				distance := math.sqrt(if r2 > 1e-12 { r2 } else { 1e-12 })
				hmr := h - distance
				rho_product := density[i] * density[j]
				pressure_scale := pressure_coeff * (hmr * hmr / distance) * (density[i] + density[j] - 2000.0) / rho_product
				viscosity_scale := viscosity_coeff * hmr / rho_product
				for axis in 0 .. 3 {
					force := disp[axis] * pressure_scale + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale
					acceleration[i][axis] += force
					acceleration[j][axis] -= force
				}
			}
		}
		for i in 0 .. count {
			base := 5 * i
			store_f64_le(mut output, 8 * base, density[i])
			store_f64_le(mut output, 8 * (base + 1), 3.0 * (density[i] - 1000.0))
			for axis in 0 .. 3 { store_f64_le(mut output, 8 * (base + 2 + axis), acceleration[i][axis]) }
		}
		return i64(output_bytes)
	}
}
