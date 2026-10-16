package softmax

import "core:c"
import "core:math"

@(export)
softmax :: proc "c" (values: [^]f64, length: c.size_t,
                      output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length < c.size_t(1) || length > c.size_t(64) do return -1
	for i := 0; i < int(length); i += 1 {
		if values[i] != values[i] || values[i] < -20.0 || values[i] > 20.0 do return -1
	}
	if output == nil || capacity < length do return -2

	total := 0.0
	for i := 0; i < int(length); i += 1 { total += math.exp_f64(values[i]) }
	for i := 0; i < int(length); i += 1 { output[i] = math.exp_f64(values[i]) / total }
	return i64(length)
}
