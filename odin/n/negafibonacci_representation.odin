package negafibonacci_representation

import "core:c"

MAX_INDEX :: 17
VALUE_LIMIT :: 1000

encode :: proc(value: i64, output: [^]u8) -> int {
	fib: [MAX_INDEX+1]i64 = {}
	weight: [MAX_INDEX+1]i64 = {}
	low: [MAX_INDEX+1]i64 = {}
	high: [MAX_INDEX+1]i64 = {}
	digit: [MAX_INDEX+1]u8 = {}
	fib[1] = 1
	fib[2] = 1
	for k := 3; k <= MAX_INDEX; k += 1 { fib[k] = fib[k-1] + fib[k-2] }
	for k := 1; k <= MAX_INDEX; k += 1 {
		weight[k] = fib[k]
		if k % 2 == 0 { weight[k] = -fib[k] }
	}
	for k := 1; k <= MAX_INDEX; k += 1 {
		suffix_low, suffix_high := i64(0), i64(0)
		if k > 1 { suffix_low = low[k-2]; suffix_high = high[k-2] }
		with_low := weight[k] + suffix_low
		with_high := weight[k] + suffix_high
		low[k] = low[k-1]
		if with_low < low[k] { low[k] = with_low }
		high[k] = high[k-1]
		if with_high > high[k] { high[k] = with_high }
	}
	remaining := value
	selected_above := false
	for k := MAX_INDEX; k > 0; k -= 1 {
		choose := false
		if !selected_above {
			suffix_low, suffix_high := i64(0), i64(0)
			if k > 1 { suffix_low = low[k-2]; suffix_high = high[k-2] }
			candidate := remaining - weight[k]
			choose = suffix_low <= candidate && candidate <= suffix_high
		}
		if choose { digit[k] = 1; remaining -= weight[k] }
		selected_above = choose
	}
	highest := MAX_INDEX
	for highest > 1 && digit[highest] == 0 { highest -= 1 }
	for k := highest; k > 0; k -= 1 {
		output[highest-k] = u8('0')
		if digit[k] == 1 { output[highest-k] = u8('1') }
	}
	return highest
}

@(export)
negafibonacci_representation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	value := input[0]
	if value < -VALUE_LIMIT || value > VALUE_LIMIT do return -1
	staged: [MAX_INDEX]u8 = {}
	required := encode(value, &staged[0])
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 { output[index] = staged[index] }
	return i64(required)
}
