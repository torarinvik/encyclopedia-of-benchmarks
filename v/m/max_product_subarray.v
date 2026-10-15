module max_product_subarray

@[export: 'max_product_subarray']
pub fn max_product_subarray(values &i64, length usize) i64 {
	if length > 9 { return i64(-9223372036854775807) - 1 }
	if length == 0 { return 0 }
	if values[0] < -10 || values[0] > 10 { return i64(-9223372036854775807) - 1 }
	mut max_now := values[0]
	mut min_now := values[0]
	mut max_product := values[0]
	for i in 1 .. length {
		value := values[i]
		if value < -10 || value > 10 { return i64(-9223372036854775807) - 1 }
		if value < 0 { swap := max_now; max_now = min_now; min_now = swap }
		max_now = if value > max_now * value { value } else { max_now * value }
	min_now = if value < min_now * value { value } else { min_now * value }
		if max_now > max_product { max_product = max_now }
	}
	return max_product
}
