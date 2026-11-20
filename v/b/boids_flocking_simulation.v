module boids_flocking_simulation

const max_boids = 16
const separation_scale = i64(256)

struct Vec2 {
	x i64
	y i64
}

fn trunc_zero(numerator i64, denominator i64) i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}

fn ceil_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(4096)
	for low < high {
		middle := (low + high) / 2
		if middle * middle < value { low = middle + 1 } else { high = middle }
	}
	return low
}

fn cap_vector(x i64, y i64, limit i64) Vec2 {
	squared := x*x + y*y
	if squared <= limit*limit { return Vec2{x, y} }
	if limit == 0 { return Vec2{0, 0} }
	length := ceil_sqrt(squared)
	return Vec2{trunc_zero(x*limit, length), trunc_zero(y*limit, length)}
}

fn request_acceleration(index int, count int, x []i64, y []i64, vx []i64, vy []i64,
	radius_squared i64, max_acceleration i64) Vec2 {
	mut sx, mut sy, mut velocity_x, mut velocity_y, mut offset_x, mut offset_y := i64(0), i64(0), i64(0), i64(0), i64(0), i64(0)
	mut neighbors := i64(0)
	for other in 0 .. count {
		if other == index { continue }
		dx := x[other] - x[index]
		dy := y[other] - y[index]
		distance_squared := dx*dx + dy*dy
		if distance_squared > radius_squared { continue }
		neighbors++
		if distance_squared == 0 {
			if index < other { sx -= separation_scale } else { sx += separation_scale }
		} else {
			length := ceil_sqrt(distance_squared)
			sx += trunc_zero(-dx*separation_scale, length)
			sy += trunc_zero(-dy*separation_scale, length)
		}
		velocity_x += vx[other]
		velocity_y += vy[other]
		offset_x += dx
		offset_y += dy
	}
	if neighbors == 0 { return Vec2{0, 0} }
	requests := [3]Vec2{
		cap_vector(trunc_zero(sx, neighbors), trunc_zero(sy, neighbors), max_acceleration),
		cap_vector(trunc_zero(velocity_x, neighbors)-vx[index], trunc_zero(velocity_y, neighbors)-vy[index], max_acceleration),
		cap_vector(trunc_zero(offset_x, neighbors), trunc_zero(offset_y, neighbors), max_acceleration),
	}
	mut ax, mut ay, mut used := i64(0), i64(0), i64(0)
	for request in requests {
		remaining := max_acceleration - used
		if remaining <= 0 { break }
		length := ceil_sqrt(request.x*request.x + request.y*request.y)
		if length == 0 { continue }
		if length <= remaining {
			ax += request.x; ay += request.y; used += length
		} else {
			trimmed := cap_vector(request.x, request.y, remaining)
			ax += trimmed.x; ay += trimmed.y
			break
		}
	}
	return Vec2{ax, ay}
}

fn store_i32_le(mut output &u8, offset int, value i64) {
	bits := u32(i32(value))
	unsafe {
		for byte in 0 .. 4 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'boids_flocking_simulation']
pub fn boids_flocking_simulation(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 9 || length > 70 { return -1 }
		n_value := input[0]
		steps := input[1]
		radius := input[2]
		max_speed := input[3]
		max_acceleration := input[4]
		if n_value < 1 || n_value > max_boids || steps < 0 || steps > 16
			|| radius < 0 || radius > 128 || max_speed < 1 || max_speed > 32
			|| max_acceleration < 0 || max_acceleration > 8
			|| length != usize(5 + 4 * n_value) { return -1 }
		n := int(n_value)
		mut x := [max_boids]i64{}
		mut y := [max_boids]i64{}
		mut vx := [max_boids]i64{}
		mut vy := [max_boids]i64{}
		mut next_x := [max_boids]i64{}
		mut next_y := [max_boids]i64{}
		mut next_vx := [max_boids]i64{}
		mut next_vy := [max_boids]i64{}
		for i in 0 .. n {
			x[i] = input[5 + 4*i]; y[i] = input[6 + 4*i]
			vx[i] = input[7 + 4*i]; vy[i] = input[8 + 4*i]
			if x[i] < -256 || x[i] > 256 || y[i] < -256 || y[i] > 256
				|| vx[i] < -32 || vx[i] > 32 || vy[i] < -32 || vy[i] > 32
				|| vx[i]*vx[i] + vy[i]*vy[i] > max_speed*max_speed { return -1 }
		}
		needed := 16 * n
		if output == nil || output_capacity < usize(needed) { return -2 }
		radius_squared := radius * radius
		for _ in 0 .. int(steps) {
			for i in 0 .. n {
				acceleration := request_acceleration(i, n, x[..n], y[..n], vx[..n], vy[..n], radius_squared, max_acceleration)
				velocity := cap_vector(vx[i] + acceleration.x, vy[i] + acceleration.y, max_speed)
				next_vx[i] = velocity.x; next_vy[i] = velocity.y
				next_x[i] = x[i] + velocity.x; next_y[i] = y[i] + velocity.y
			}
			for i in 0 .. n { x[i] = next_x[i]; y[i] = next_y[i]; vx[i] = next_vx[i]; vy[i] = next_vy[i] }
		}
		for i in 0 .. n {
			store_i32_le(mut output, 16*i, x[i]); store_i32_le(mut output, 16*i+4, y[i])
			store_i32_le(mut output, 16*i+8, vx[i]); store_i32_le(mut output, 16*i+12, vy[i])
		}
		return i64(needed)
	}
}
