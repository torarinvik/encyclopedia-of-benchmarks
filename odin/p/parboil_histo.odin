package parboil_histo

import "core:c"

@(export)
parboil_histo :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 1027 do return -1
	iterations, bins, samples := input[0], input[1], input[2]
	if iterations < 0 || iterations > 8 || bins < 1 || bins > 256 || samples < 0 || samples > 1024 do return -1
	if length != c.size_t(3 + samples) do return -1
	for i := 0; i < int(samples); i += 1 { if input[3+i] < 0 || input[3+i] >= bins do return -1 }
	if output == nil || capacity < c.size_t(bins) do return -2
	histogram: [256]u8 = {}
	for iter := i64(0); iter < iterations; iter += 1 {
		for i := 0; i < int(bins); i += 1 { histogram[i] = 0 }
		for i := 0; i < int(samples); i += 1 {
			bin := int(input[3+i])
			if histogram[bin] < 255 do histogram[bin] += 1
		}
	}
	for i := 0; i < int(bins); i += 1 { output[i] = histogram[i] }
	return bins
}
