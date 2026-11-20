package boids_flocking_simulation

import "core:c"

MAX_BOIDS :: 16
SEPARATION_SCALE :: i64(256)

trunc_zero :: proc(numerator, denominator: i64) -> i64 {
	if numerator < 0 do return -((-numerator) / denominator)
	return numerator / denominator
}

ceil_sqrt :: proc(value: i64) -> i64 {
	low, high := i64(0), i64(4096)
	for low < high {
		middle := (low + high) / 2
		if middle * middle < value do low = middle + 1 else high = middle
	}
	return low
}

cap_vector :: proc(x, y, limit: i64, out_x, out_y: ^i64) {
	squared := x*x + y*y
	if squared <= limit*limit { out_x^ = x; out_y^ = y; return }
	if limit == 0 { out_x^ = 0; out_y^ = 0; return }
	length := ceil_sqrt(squared)
	out_x^ = trunc_zero(x*limit, length)
	out_y^ = trunc_zero(y*limit, length)
}

request_acceleration :: proc(index, count: int, x, y, vx, vy: [^]i64,
	radius_squared, max_acceleration: i64, out_x, out_y: ^i64) {
	sx, sy, velocity_x, velocity_y, offset_x, offset_y := i64(0), i64(0), i64(0), i64(0), i64(0), i64(0)
	neighbors := i64(0)
	for other := 0; other < count; other += 1 {
		if other == index do continue
		dx, dy := x[other]-x[index], y[other]-y[index]
		distance_squared := dx*dx + dy*dy
		if distance_squared > radius_squared do continue
		neighbors += 1
		if distance_squared == 0 {
			if index < other do sx -= SEPARATION_SCALE else sx += SEPARATION_SCALE
		} else {
			length := ceil_sqrt(distance_squared)
			sx += trunc_zero(-dx*SEPARATION_SCALE, length)
			sy += trunc_zero(-dy*SEPARATION_SCALE, length)
		}
		velocity_x += vx[other]; velocity_y += vy[other]
		offset_x += dx; offset_y += dy
	}
	if neighbors == 0 { out_x^ = 0; out_y^ = 0; return }
	request_x: [3]i64 = {}
	request_y: [3]i64 = {}
	cap_vector(trunc_zero(sx, neighbors), trunc_zero(sy, neighbors), max_acceleration, &request_x[0], &request_y[0])
	cap_vector(trunc_zero(velocity_x, neighbors)-vx[index], trunc_zero(velocity_y, neighbors)-vy[index], max_acceleration, &request_x[1], &request_y[1])
	cap_vector(trunc_zero(offset_x, neighbors), trunc_zero(offset_y, neighbors), max_acceleration, &request_x[2], &request_y[2])
	ax, ay, used := i64(0), i64(0), i64(0)
	for rule := 0; rule < 3; rule += 1 {
		remaining := max_acceleration - used
		if remaining <= 0 do break
		length := ceil_sqrt(request_x[rule]*request_x[rule] + request_y[rule]*request_y[rule])
		if length == 0 do continue
		if length <= remaining {
			ax += request_x[rule]; ay += request_y[rule]; used += length
		} else {
			tx, ty: i64
			cap_vector(request_x[rule], request_y[rule], remaining, &tx, &ty)
			ax += tx; ay += ty
			break
		}
	}
	out_x^ = ax; out_y^ = ay
}

store_i32_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8((bits >> (byte*8)) & 255)
	}
}

@(export)
boids_flocking_simulation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > 70 do return -1
	n_value, steps, radius := input[0], input[1], input[2]
	max_speed, max_acceleration := input[3], input[4]
	if n_value < 1 || n_value > MAX_BOIDS || steps < 0 || steps > 16
		|| radius < 0 || radius > 128 || max_speed < 1 || max_speed > 32
		|| max_acceleration < 0 || max_acceleration > 8
		|| length != c.size_t(5 + 4*int(n_value)) do return -1
	n := int(n_value)
	x, y, vx, vy := [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}
	nx, ny, nvx, nvy := [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}, [MAX_BOIDS]i64{}
	for i := 0; i < n; i += 1 {
		x[i], y[i], vx[i], vy[i] = input[5+4*i], input[6+4*i], input[7+4*i], input[8+4*i]
		if x[i] < -256 || x[i] > 256 || y[i] < -256 || y[i] > 256
			|| vx[i] < -32 || vx[i] > 32 || vy[i] < -32 || vy[i] > 32
			|| vx[i]*vx[i] + vy[i]*vy[i] > max_speed*max_speed do return -1
	}
	needed := c.size_t(16*n)
	if output == nil || output_capacity < needed do return -2
	radius_squared := radius * radius
	for step := i64(0); step < steps; step += 1 {
		for i := 0; i < n; i += 1 {
			ax, ay: i64
			request_acceleration(i, n, &x[0], &y[0], &vx[0], &vy[0], radius_squared, max_acceleration, &ax, &ay)
			cap_vector(vx[i]+ax, vy[i]+ay, max_speed, &nvx[i], &nvy[i])
			nx[i], ny[i] = x[i]+nvx[i], y[i]+nvy[i]
		}
		for i := 0; i < n; i += 1 { x[i], y[i], vx[i], vy[i] = nx[i], ny[i], nvx[i], nvy[i] }
	}
	for i := 0; i < n; i += 1 {
		offset := 16*i
		store_i32_le(output, offset, x[i]); store_i32_le(output, offset+4, y[i])
		store_i32_le(output, offset+8, vx[i]); store_i32_le(output, offset+12, vy[i])
	}
	return i64(needed)
}
