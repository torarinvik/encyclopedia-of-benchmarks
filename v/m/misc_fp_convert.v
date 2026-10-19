module misc_fp_convert

const max_iterations = i64(256)
const vector_length = 2048

@[export: 'misc_fp_convert']
pub fn misc_fp_convert(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length != 1 { return -1 }
		requested := input[0]
		if requested != requested || requested < 1.0 || requested > f64(max_iterations) || f64(i64(requested)) != requested { return -1 }
		if isnil(output) || output_capacity < 1 { return -2 }

		iterations := i64(requested)
		mut x := [vector_length]f32{}
		mut y := [vector_length]f32{}
		mut a := f32(0)
		mut b := f32(1)
		mut total := f64(0)
		for iteration in 0 .. int(iterations) {
			if iteration % 10 != 0 {
				a = f32(0)
				b = f32(1)
			} else {
				a += f32(0.1)
				b += f32(0.2)
			}
			for index in 0 .. vector_length {
				x[index] = a + f32(index)
				y[index] = b + f32(index)
			}
			mut accumulator := f64(0)
			for index in 0 .. vector_length {
				accumulator += f64(x[index]) * f64(y[index])
			}
			total += accumulator
		}
		output[0] = total
		return 1
	}
}
