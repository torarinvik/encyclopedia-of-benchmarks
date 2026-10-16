package dispersion

import "core:c"
import "core:math"

Max_Input :: 128

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
dispersion :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length == 0 || length > c.size_t(Max_Input) do return -1
	for i := 0; i < int(length); i += 1 {
		if values[i] < -10000 || values[i] > 10000 do return -1
	}
	if output == nil || capacity < 16 do return -2
	sum := f64(0)
	for i := 0; i < int(length); i += 1 { sum += f64(values[i]) }
	mean := sum / f64(length)
	squared_deviations := f64(0)
	for i := 0; i < int(length); i += 1 {
		deviation := f64(values[i]) - mean
		squared_deviations += deviation * deviation
	}
	variance := squared_deviations / f64(length)
	put_f64_le(output, 0, variance)
	put_f64_le(output, 8, math.sqrt(variance))
	return 16
}
