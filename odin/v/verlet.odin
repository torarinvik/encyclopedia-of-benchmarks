package verlet

import "core:c"

@(export)
verlet :: proc "c" (values: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(4) do return -1
	for i := 0; i < 4; i += 1 {
		if values[i] != values[i] do return -1
	}
	if values[0] < 2.0 || values[0] > 32.0 || values[0] != f64(int(values[0])) ||
		values[1] < -1.0 || values[1] > 1.0 ||
		values[2] < -1.0 || values[2] > 1.0 ||
		values[3] < 0.0 || values[3] > 4.0 || values[3] != f64(int(values[3])) do return -1

	n := int(values[0])
	code := int(values[3])
	dt := f64(0.00390625)
	switch code {
	case 1: dt = 0.0078125
	case 2: dt = 0.015625
	case 3: dt = 0.03125
	case 4: dt = 0.0625
	}
	dt_squared := dt * dt
	if output == nil || capacity < c.size_t(2*n) do return -2

	output[0] = values[1]
	output[1] = values[1] + values[2]*dt + 0.5*(-values[1])*dt_squared
	for i := 1; i < n-1; i += 1 {
		output[i+1] = 2.0*output[i] - output[i-1] + (-output[i])*dt_squared
	}
	for i := 0; i < n; i += 1 {
		output[n+i] = f64(i) * dt
	}
	return i64(2 * n)
}
