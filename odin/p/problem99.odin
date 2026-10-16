package problem99

import "core:c"
import "core:math"

const MAX_PAIR_COUNT = 1000
const MAX_BASE: i64 = 1_000_000
const MAX_EXPONENT: i64 = 1_200_000

@(export)
problem99 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	pair_count_value := input[0]
	if pair_count_value < 0 || pair_count_value > i64(MAX_PAIR_COUNT) do return -1
	pair_count := int(pair_count_value)
	if length != c.size_t(1 + 2 * pair_count) do return -1

	largest := f64(0)
	result := i64(0)
	for index := 0; index < pair_count; index += 1 {
		base := input[1 + 2 * index]
		exponent := input[2 + 2 * index]
		if base < 1 || base > MAX_BASE || exponent < 0 || exponent > MAX_EXPONENT do return -1
		value := f64(exponent) * math.log10_f64(f64(base))
		if value > largest {
			largest = value
			result = i64(index + 1)
		}
	}
	return result
}
