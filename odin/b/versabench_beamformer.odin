package versabench_beamformer
import "core:c"

@(export)
versabench_beamformer :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 48 do return -1
	values: [48]f32 = {}
	for i := 0; i < 48; i += 1 {
		x := input[i]
		if x != x || x < -128.0 || x > 128.0 do return -1
		values[i] = f32(x)
	}
	var real, imag: f32 = 0, 0
	for channel := 0; channel < 12; channel += 1 {
		b := 4 * channel
		rr := values[b] * values[b+2] - values[b+1] * values[b+3]
		ii := values[b] * values[b+3] + values[b+1] * values[b+2]
		real = real + rr
		imag = imag + ii
	}
	if output == nil || capacity < 2 do return -2
	output[0] = f64(real); output[1] = f64(imag)
	return 2
}
