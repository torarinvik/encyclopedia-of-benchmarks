package interquartile_range

import "core:c"

median_i64 :: proc "contextless" (values: [^]i64, count: int) -> f64 {
	if count % 2 != 0 do return f64(values[count/2])
	return (f64(values[count/2-1]) + f64(values[count/2])) / 2.0
}

@(export)
interquartile_range :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > 64 do return -1.0e300
	var sorted: [64]i64
	for i := 0; i < int(length); i += 1 {
		if values[i] < -1000000 || values[i] > 1000000 do return -1.0e300
		sorted[i] = values[i]
	}
	for i := 1; i < int(length); i += 1 {
		key := sorted[i]; j := i
		for j > 0 && sorted[j-1] > key { sorted[j] = sorted[j-1]; j -= 1 }
		sorted[j] = key
	}
	half := int(length) / 2
	upper_start := half + int(length) % 2
	return median_i64(&sorted[upper_start], half) - median_i64(&sorted[0], half)
}
