module max_product_of_three

@[export: 'max_product_of_three']
pub fn max_product_of_three(input &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if unsafe { input == nil } || length == 0 { return invalid }
	n_value := unsafe { input[0] }
	if n_value < 3 || n_value > 128 || length != usize(n_value + 1) { return invalid }
	n := int(n_value)
	for i in 0 .. n { value := unsafe { input[i + 1] }; if value < -1000 || value > 1000 { return invalid } }
	mut max1 := unsafe { input[1] }; mut max2 := i64(-1001); mut max3 := i64(-1001)
	mut min1 := unsafe { input[1] }; mut min2 := i64(1001)
	for i := 1; i < n; i++ {
		value := unsafe { input[i + 1] }
		if value > max1 { max3 = max2; max2 = max1; max1 = value }
		else if value > max2 { max3 = max2; max2 = value }
		else if value > max3 { max3 = value }
		if value < min1 { min2 = min1; min1 = value }
		else if value < min2 { min2 = value }
	}
	product1 := max1 * max2 * max3
	product2 := max1 * min1 * min2
	return if product1 > product2 { product1 } else { product2 }
}
