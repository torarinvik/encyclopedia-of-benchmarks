module perlin_noise

const max_dimension = 8
const max_input_elements = 5
const max_parseable_input_elements = 6
const max_output_elements = max_dimension * max_dimension
const java_multiplier = u64(0x5deece66d)
const java_addend = u64(0xb)
const java_mask = (u64(1) << 48) - 1

fn rounded_add(a f32, b f32) f32 { return a + b }
fn rounded_sub(a f32, b f32) f32 { return a - b }
fn rounded_mul(a f32, b f32) f32 { return a * b }
fn rounded_div(a f32, b f32) f32 { return a / b }

fn java_next(mut state u64, bits u32) u32 {
	state = (state *% java_multiplier +% java_addend) & java_mask
	return u32(state >> (48 - bits))
}

fn interpolate(a f32, b f32, alpha f32) f32 {
	one_minus_alpha := rounded_sub(f32(1.0), alpha)
	left := rounded_mul(a, one_minus_alpha)
	right := rounded_mul(alpha, b)
	return rounded_add(left, right)
}

fn exact_integer(value f64, minimum f64, maximum f64) bool {
	return value == value && value >= minimum && value <= maximum && f64(i64(value)) == value
}

@[export: 'perlin_noise']
pub fn perlin_noise(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_parseable_input_elements { return -1 }
		if length != max_input_elements { return -1 }
		if !exact_integer(input[0], 1.0, 8.0) || !exact_integer(input[1], 1.0, 8.0) ||
			!exact_integer(input[2], 1.0, 4.0) || !exact_integer(input[4], 0.0, 2147483647.0) ||
			(input[3] != 0.5 && input[3] != 0.75 && input[3] != 1.0) { return -1 }
		width, height, octave_count := int(input[0]), int(input[1]), int(input[2])
		seed := u64(input[4])
		count := width * height
		mut base := [max_output_elements]f32{}
		mut layers := [4 * max_output_elements]f32{}
		mut result := [max_output_elements]f32{}
		mut state := (seed ^ java_multiplier) & java_mask
		for x in 0 .. width { for y in 0 .. height {
			base[x * height + y] = rounded_div(f32(java_next(mut state, 24)), f32(16777216.0))
		} }
		for octave in 0 .. octave_count {
			period := 1 << octave
			frequency := rounded_div(f32(1.0), f32(period))
			offset := octave * max_output_elements
			for x in 0 .. width {
				x0 := (x / period) * period
				x1 := (x0 + period) % width
				horizontal := rounded_mul(f32(x - x0), frequency)
				for y in 0 .. height {
					y0 := (y / period) * period
					y1 := (y0 + period) % height
					vertical := rounded_mul(f32(y - y0), frequency)
					top := interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal)
					bottom := interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal)
					layers[offset + x * height + y] = interpolate(top, bottom, vertical)
				}
			}
		}
		persistence := f32(input[3])
		mut amplitude := f32(1.0)
		mut total_amplitude := f32(0.0)
		for octave := octave_count - 1; octave >= 0; octave-- {
			amplitude = rounded_mul(amplitude, persistence)
			total_amplitude = rounded_add(total_amplitude, amplitude)
			offset := octave * max_output_elements
			for i in 0 .. count { result[i] = rounded_add(result[i], rounded_mul(layers[offset + i], amplitude)) }
		}
		inverse_total := rounded_div(f32(1.0), total_amplitude)
		for i in 0 .. count { result[i] = rounded_mul(result[i], inverse_total) }
		if output == nil || output_capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = f64(result[i]) }
		return i64(count)
	}
}
