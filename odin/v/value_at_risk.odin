package value_at_risk

import "core:c"

SCALE::i64 = 1_000_000
MAX_RETURNS::int = 64
MAX_PARSED_RETURNS::i64 = 65
MAX_SAMPLE::i64 = 1_000_000_000
MAX_INPUT_LENGTH::c.size_t = 67
INVALID_RESULT::f64 = -1.0e300

sift_down :: proc "contextless" (values: [^]f64, root_start, end_value: int) {
	root := root_start
	for root < end_value / 2 {
		child := root * 2 + 1
		if child + 1 < end_value && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

heap_sort :: proc "contextless" (values: [^]f64, length: int) {
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, length)
	}
	ending := length
	for ending > 1 {
		ending -= 1
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		sift_down(values, 0, ending)
	}
}

@(export)
value_at_risk :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	confidence_micro, count_value := input[0], input[1]
	if confidence_micro < 1 || confidence_micro >= SCALE || count_value < 1 || count_value > MAX_PARSED_RETURNS do return INVALID_RESULT
	if length != c.size_t(2 + count_value) || count_value > i64(MAX_RETURNS) do return INVALID_RESULT
	count := int(count_value)
	returns: [MAX_RETURNS]f64
	for index := 0; index < count; index += 1 {
		value := input[2 + index]
		if value < -MAX_SAMPLE || value > MAX_SAMPLE do return INVALID_RESULT
		returns[index] = f64(value) / f64(SCALE)
	}
	heap_sort(&returns[0], count)
	confidence := f64(confidence_micro) / f64(SCALE)
	quantile := f64(1.0) - confidence
	position := f64(count - 1) * quantile
	lower := int(position)
	fraction := position - f64(lower)
	threshold := returns[lower]
	if lower + 1 < count do threshold = returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction
	return -threshold
}
