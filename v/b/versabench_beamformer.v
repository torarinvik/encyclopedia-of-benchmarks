module versabench_beamformer

@[export: 'versabench_beamformer']
pub fn versabench_beamformer(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if input == nil || length != 48 { return -1 }
	mut values := [48]f32{}
	unsafe {
		for i in 0 .. 48 {
			x := input[i]
			if x != x || x < -128.0 || x > 128.0 { return -1 }
			values[i] = f32(x)
		}
	}
	mut real := f32(0)
	mut imag := f32(0)
	for channel in 0 .. 12 {
		b := 4 * channel
		rr := values[b] * values[b + 2] - values[b + 1] * values[b + 3]
		ii := values[b] * values[b + 3] + values[b + 1] * values[b + 2]
		real = real + rr
		imag = imag + ii
	}
	if output == nil || capacity < 2 { return -2 }
	unsafe { output[0] = f64(real); output[1] = f64(imag) }
	return 2
}
