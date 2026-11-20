import math

const min_coordinate = i64(900)
const max_coordinate = i64(1500)
const max_updates = i64(8)

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn round_nano(value f64) i64 {
	magnitude := if value < 0.0 { 0.0 - value } else { value }
	rounded := i64(math.floor(magnitude * 1_000_000_000.0 + 0.5))
	return if value < 0.0 { -rounded } else { rounded }
}

@[export: 'multidimensional_newton_raphson']
pub fn multidimensional_newton_raphson(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 4 { return -1 }
		if length != 3 { return -1 }
		x_milli := input[0]
		y_milli := input[1]
		updates := input[2]
		if x_milli < min_coordinate || x_milli > max_coordinate ||
			y_milli < min_coordinate || y_milli > max_coordinate ||
			updates < 1 || updates > max_updates { return -1 }
		if output == nil || capacity < 16 { return -2 }

		mut x := f64(x_milli) / 1000.0
		mut y := f64(y_milli) / 1000.0
		for _ in 0 .. updates {
			f1 := x * x + y - 3.0
			f2 := x + y * y - 3.0
			determinant := 4.0 * x * y - 1.0
			dx := (2.0 * y * f1 - f2) / determinant
			dy := (2.0 * x * f2 - f1) / determinant
			x -= dx
			y -= dy
		}
		store_i64_le(mut output, 0, round_nano(x))
		store_i64_le(mut output, 8, round_nano(y))
		return 16
	}
}
