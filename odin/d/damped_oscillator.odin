package damped_oscillator

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
damped_oscillator :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 5 do return -1
	if input[0] < 1 || input[0] > 1024 || input[1] < 0 || input[1] > 1024 ||
		input[2] < -1024 || input[2] > 1024 || input[3] < -1024 || input[3] > 1024 ||
		input[4] < 1 || input[4] > 1024 do return -1
	if output == nil || capacity < 16 do return -2
	omega0 := f64(input[0]) / 1024.0
	gamma := f64(input[1]) / 1024.0
	x := f64(input[2]) / 1024.0
	v := f64(input[3]) / 1024.0
	dt := f64(input[4]) / 1024.0
	acceleration := -2.0 * gamma * v - omega0 * omega0 * x
	x_next := x + dt * v
	v_next := v + dt * acceleration
	put_f64_le(output, 0, x_next)
	put_f64_le(output, 8, v_next)
	return 16
}
