package single_parameter_truthful_payment

import "core:c"

MAX_STEPS :: 8
MAX_INPUT :: 18
MAX_BID :: 16
MAX_OUTPUT :: 16

put_i64 :: proc(out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset+b] = u8((bits >> (b*8)) & 255) }
}

@(export)
single_parameter_truthful_payment :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || int(length) < 4 || int(length) > MAX_INPUT do return -1
	if values[0] < 0 || values[0] > i64(MAX_BID) || values[1] < 1 || values[1] > i64(MAX_STEPS) do return -1
	bid, k := int(values[0]), int(values[1])
	if int(length) != 2+2*k do return -1
	for i := 0; i < k; i += 1 {
		point, load := values[2+2*i], values[3+2*i]
		if point < 0 || point >= MAX_BID || load < 0 || load > MAX_BID do return -1
		if i == 0 && point != 0 do return -1
		if i > 0 && (point <= values[2+2*(i-1)] || load > values[3+2*(i-1)]) do return -1
	}
	allocation: i64 = 0
	if bid < MAX_BID { for i := 0; i < k; i += 1 { if int(values[2+2*i]) <= bid do allocation = values[3+2*i] } }
	area: i64 = 0
	for i := 0; i < k; i += 1 {
		start := int(values[2+2*i])
		finish := MAX_BID
		if i+1 < k { finish = int(values[2+2*(i+1)]) }
		left := start
		if bid > left { left = bid }
		if finish > left { area += i64(finish-left) * values[3+2*i] }
	}
	payment := i64(bid)*allocation + area
	if output == nil || int(capacity) < MAX_OUTPUT do return -2
	staged: [MAX_OUTPUT]u8
	put_i64(&staged[0], 0, allocation)
	put_i64(&staged[0], 8, payment)
	for i := 0; i < MAX_OUTPUT; i += 1 { output[i] = staged[i] }
	return MAX_OUTPUT
}
