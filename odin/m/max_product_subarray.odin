package max_product_subarray

INVALID_RESULT :: i64(-9223372036854775807 - 1)

@(export)
max_product_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 9 || (length > 0 && values == nil) do return INVALID_RESULT
	if length == 0 do return 0
	if values[0] < -10 || values[0] > 10 do return INVALID_RESULT
	max_now, min_now, max_product := values[0], values[0], values[0]
	for i := 1; i < int(length); i += 1 {
		value := values[i]
		if value < -10 || value > 10 do return INVALID_RESULT
		if value < 0 { swap := max_now; max_now = min_now; min_now = swap }
		max_now = max(value, max_now * value)
	min_now = min(value, min_now * value)
	max_product = max(max_product, max_now)
	}
	return max_product
}
