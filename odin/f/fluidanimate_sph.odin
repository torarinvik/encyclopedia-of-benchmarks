package fluidanimate_sph

import "core:c"
import "core:math"

MAX_PARTICLES :: 32
MAX_INPUT_LENGTH :: 2 + 6 * MAX_PARTICLES
PI :: 3.14159265358979323846264338327950288

store_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(8*byte))
	}
}

@(export)
fluidanimate_sph :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	count_value, rpm_milli := input[0], input[1]
	if count_value < 1 || count_value > MAX_PARTICLES || rpm_milli < 500 || rpm_milli > 5000 do return -1
	count := int(count_value)
	if length != c.size_t(2+6*count) do return -1
	for i := 0; i < count; i += 1 {
		base := 2+6*i
		for axis := 0; axis < 3; axis += 1 {
			if input[base+axis] < -10000 || input[base+axis] > 10000 do return -1
			if input[base+3+axis] < -5000 || input[base+3+axis] > 5000 do return -1
		}
	}
	output_bytes := c.size_t(40*count)
	if output == nil || capacity < output_bytes do return -2

	position: [MAX_PARTICLES][3]f64
	velocity: [MAX_PARTICLES][3]f64
	acceleration: [MAX_PARTICLES][3]f64
	density: [MAX_PARTICLES]f64
	rpm := f64(rpm_milli)/1000.0
	h := 1.695/rpm
	h2 := h*h
	mass := 1000.0/(rpm*rpm*rpm)
	density_coeff := mass*(315.0/(64.0*PI*math.pow_f64(h,9.0)))
	pressure_coeff := 3.0*(15.0/(PI*math.pow_f64(h,6.0)))*1.5*mass
	viscosity_coeff := 0.4*(45.0/(PI*math.pow_f64(h,6.0)))*mass
	for i := 0; i < count; i += 1 {
		base := 2+6*i
		for axis := 0; axis < 3; axis += 1 {
			position[i][axis] = f64(input[base+axis])/1000.0
			velocity[i][axis] = f64(input[base+3+axis])/1000.0
			acceleration[i][axis] = 0.0
		}
		acceleration[i][1] = -9.8
		density[i] = density_coeff*h2*h2*h2
	}
	for i := 0; i < count; i += 1 {
		for j := i+1; j < count; j += 1 {
			dx, dy, dz := position[i][0]-position[j][0], position[i][1]-position[j][1], position[i][2]-position[j][2]
			r2 := dx*dx+dy*dy+dz*dz
			if r2 < h2 {
				term := density_coeff*math.pow_f64(h2-r2,3.0)
				density[i] += term
				density[j] += term
			}
		}
	}
	for i := 0; i < count; i += 1 {
		for j := i+1; j < count; j += 1 {
			disp := [3]f64{position[i][0]-position[j][0], position[i][1]-position[j][1], position[i][2]-position[j][2]}
			r2 := disp[0]*disp[0]+disp[1]*disp[1]+disp[2]*disp[2]
			if r2 >= h2 do continue
			guarded_r2 := r2
			if guarded_r2 < 1e-12 do guarded_r2 = 1e-12
			distance := math.sqrt_f64(guarded_r2)
			hmr := h-distance
			rho_product := density[i]*density[j]
			pressure_scale := pressure_coeff*(hmr*hmr/distance)*(density[i]+density[j]-2000.0)/rho_product
			viscosity_scale := viscosity_coeff*hmr/rho_product
			for axis := 0; axis < 3; axis += 1 {
				force := disp[axis]*pressure_scale+(velocity[j][axis]-velocity[i][axis])*viscosity_scale
				acceleration[i][axis] += force
				acceleration[j][axis] -= force
			}
		}
	}
	for i := 0; i < count; i += 1 {
		base := 5*i
		store_f64_le(output, 8*base, density[i])
		store_f64_le(output, 8*(base+1), 3.0*(density[i]-1000.0))
		for axis := 0; axis < 3; axis += 1 { store_f64_le(output, 8*(base+2+axis), acceleration[i][axis]) }
	}
	return i64(output_bytes)
}
