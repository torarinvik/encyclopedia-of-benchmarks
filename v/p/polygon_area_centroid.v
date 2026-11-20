module polygon_area_centroid

const max_vertices = 16
const max_parseable_length = 34
const output_scale = i64(1_000_000)

fn rounded_micro(numerator_input i64, denominator_input i64) i64 {
	mut numerator := numerator_input
	mut denominator := denominator_input
	if denominator < 0 { numerator = -numerator; denominator = -denominator }
	mut sign := i64(1)
	if numerator < 0 { sign = -1 }
	mut magnitude := u64(if numerator < 0 { -numerator } else { numerator })
	let scaled := magnitude * u64(output_scale)
	let divisor := u64(denominator)
	mut quotient := scaled / divisor
	if 2 * (scaled % divisor) >= divisor { quotient++ }
	return sign * i64(quotient)
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polygon_area_centroid']
pub fn polygon_area_centroid(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 7 || length > max_parseable_length { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 3 || count_value > max_vertices { return -1 }
		count := int(count_value)
		if length != usize(1 + 2 * count) { return -1 }
		mut xs := [max_vertices]i64{init: 0}
		mut ys := [max_vertices]i64{init: 0}
		for i in 0 .. count {
			x, y := input[1 + 2 * i], input[2 + 2 * i]
			if x < -50 || x > 50 || y < -50 || y > 50 { return -1 }
			for j in 0 .. i { if xs[j] == x && ys[j] == y { return -1 } }
			xs[i], ys[i] = x, y
		}
		mut twice_area := i64(0)
		for i in 0 .. count {
			next := (i + 1) % count
			twice_area += xs[i] * ys[next] - xs[next] * ys[i]
		}
		if twice_area == 0 { return -1 }
		orientation := if twice_area > 0 { i64(1) } else { i64(-1) }
		for i in 0 .. count {
			next := (i + 1) % count
			for j in 0 .. count {
				if j == i || j == next { continue }
				side := (xs[next] - xs[i]) * (ys[j] - ys[i]) - (ys[next] - ys[i]) * (xs[j] - xs[i])
				if side * orientation <= 0 { return -1 }
			}
		}
		mut numerator_x, numerator_y := i64(0), i64(0)
		for i in 0 .. count {
			next := (i + 1) % count
			cross := xs[i] * ys[next] - xs[next] * ys[i]
			numerator_x += (xs[i] + xs[next]) * cross
			numerator_y += (ys[i] + ys[next]) * cross
		}
		x_micro := rounded_micro(numerator_x, 3 * twice_area)
		y_micro := rounded_micro(numerator_y, 3 * twice_area)
		if unsafe { output == nil } || capacity < 16 { return -2 }
		store_i64_le(mut output, 0, x_micro)
		store_i64_le(mut output, 8, y_micro)
		return 16
	}
}
