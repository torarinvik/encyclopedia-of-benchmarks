package arithmetic_decoding

import "core:c"

MAX_SYMBOLS :: 12

@(export)
arithmetic_decoding :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 do return -1
	count := input[0]
	alphabet_size := input[1]
	if count < 1 || count > MAX_SYMBOLS || alphabet_size < 1 || alphabet_size > count || length != c.size_t(3 + 2 * alphabet_size) {
		return -1
	}

	denominator: i64 = 1
	for step := i64(0); step < count; step += 1 { denominator *= count }
	code := input[2]
	if code < 0 || code >= denominator do return -1

	symbols: [MAX_SYMBOLS]i64
	cumulative: [MAX_SYMBOLS + 1]i64
	for index := 0; index <= MAX_SYMBOLS; index += 1 { cumulative[index] = 0 }
	total: i64 = 0
	for index := 0; index < int(alphabet_size); index += 1 {
		symbol := input[3 + 2 * index]
		frequency := input[4 + 2 * index]
		if symbol < 0 || symbol > 255 || frequency < 1 || frequency > count || (index > 0 && symbol <= symbols[index - 1]) {
			return -1
		}
		symbols[index] = symbol
		total += frequency
		cumulative[index + 1] = total
	}
	if total != count do return -1
	if capacity < c.size_t(count) || output == nil do return -2

	low, high: i64 = 0, 1
	scale := denominator / count
	for step := i64(0); step < count; step += 1 {
		range := high - low
		base := low * count
		found := false
		for index := 0; index < int(alphabet_size); index += 1 {
			symbol_low := base + range * cumulative[index]
			symbol_high := base + range * cumulative[index + 1]
			if code >= symbol_low * scale && code < symbol_high * scale {
				output[step] = u8(symbols[index])
				low = symbol_low
				high = symbol_high
				found = true
				break
			}
		}
		if !found do return -1
		if step + 1 < count do scale /= count
	}
	return count
}
