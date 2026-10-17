package perlin_noise

import "core:c"

MAX_DIMENSION :: 8
MAX_INPUT_ELEMENTS :: 5
MAX_PARSEABLE_INPUT_ELEMENTS :: 6
MAX_OUTPUT_ELEMENTS :: MAX_DIMENSION * MAX_DIMENSION
JAVA_MULTIPLIER :: u64(0x5DEECE66D)
JAVA_ADDEND :: u64(0xB)
JAVA_MASK :: (u64(1) << 48) - 1

rounded_add :: proc(a, b: f32) -> f32 { return a + b }
rounded_sub :: proc(a, b: f32) -> f32 { return a - b }
rounded_mul :: proc(a, b: f32) -> f32 { return a * b }
rounded_div :: proc(a, b: f32) -> f32 { return a / b }

java_next :: proc(state: ^u64, bits: u32) -> u32 {
	state^ = (state^ *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK
	return u32(state^ >> (48 - bits))
}

interpolate :: proc(a, b, alpha: f32) -> f32 {
	one_minus_alpha := rounded_sub(1.0, alpha)
	left := rounded_mul(a, one_minus_alpha)
	right := rounded_mul(alpha, b)
	return rounded_add(left, right)
}

exact_integer :: proc(value, minimum, maximum: f64) -> bool {
	return value >= minimum && value <= maximum && f64(i64(value)) == value
}

@(export)
perlin_noise :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE_INPUT_ELEMENTS do return -1
	if length != MAX_INPUT_ELEMENTS do return -1
	if !exact_integer(input[0], 1, 8) || !exact_integer(input[1], 1, 8) ||
		!exact_integer(input[2], 1, 4) || !exact_integer(input[4], 0, 2147483647) ||
		(input[3] != 0.5 && input[3] != 0.75 && input[3] != 1.0) do return -1

	width, height, octave_count := int(input[0]), int(input[1]), int(input[2])
	seed := u64(input[4])
	count := width * height
	var base: [MAX_OUTPUT_ELEMENTS]f32
	var layers: [4 * MAX_OUTPUT_ELEMENTS]f32
	var result: [MAX_OUTPUT_ELEMENTS]f32
	state := (seed ^ JAVA_MULTIPLIER) & JAVA_MASK
	for x := 0; x < width; x += 1 {
		for y := 0; y < height; y += 1 {
			base[x*height+y] = rounded_div(f32(java_next(&state, 24)), 16777216.0)
		}
	}
	for octave := 0; octave < octave_count; octave += 1 {
		period := 1 << octave
		frequency := rounded_div(1.0, f32(period))
		offset := octave * MAX_OUTPUT_ELEMENTS
		for x := 0; x < width; x += 1 {
			x0 := (x / period) * period
			x1 := (x0 + period) % width
			horizontal := rounded_mul(f32(x-x0), frequency)
			for y := 0; y < height; y += 1 {
				y0 := (y / period) * period
				y1 := (y0 + period) % height
				vertical := rounded_mul(f32(y-y0), frequency)
				top := interpolate(base[x0*height+y0], base[x1*height+y0], horizontal)
				bottom := interpolate(base[x0*height+y1], base[x1*height+y1], horizontal)
				layers[offset+x*height+y] = interpolate(top, bottom, vertical)
			}
		}
	}
	var amplitude: f32 = 1.0
	var total_amplitude: f32 = 0.0
	persistence := f32(input[3])
	for octave := octave_count-1; octave >= 0; octave -= 1 {
		amplitude = rounded_mul(amplitude, persistence)
		total_amplitude = rounded_add(total_amplitude, amplitude)
		offset := octave * MAX_OUTPUT_ELEMENTS
		for i := 0; i < count; i += 1 { result[i] = rounded_add(result[i], rounded_mul(layers[offset+i], amplitude)) }
	}
	inverse_total := rounded_div(1.0, total_amplitude)
	for i := 0; i < count; i += 1 { result[i] = rounded_mul(result[i], inverse_total) }
	if output == nil || output_capacity < c.size_t(count) do return -2
	for i := 0; i < count; i += 1 { output[i] = f64(result[i]) }
	return i64(count)
}
