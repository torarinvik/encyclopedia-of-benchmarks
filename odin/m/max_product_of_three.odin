package max_product_of_three

import "core:c"

@(export)
max_product_of_three :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	invalid: i64 = -9223372036854775807 - 1
	if length < 1 || input[0] < 3 || input[0] > 128 || int(length) != int(input[0]) + 1 do return invalid
	n := int(input[0])
	for i := 0; i < n; i += 1 { if input[i + 1] < -1000 || input[i + 1] > 1000 do return invalid }
	max1 := input[1]; max2: i64 = -1001; max3: i64 = -1001
	min1 := input[1]; min2: i64 = 1001
	for i := 1; i < n; i += 1 {
		value := input[i + 1]
		if value > max1 { max3 = max2; max2 = max1; max1 = value }
		else if value > max2 { max3 = max2; max2 = value }
		else if value > max3 { max3 = value }
		if value < min1 { min2 = min1; min1 = value }
		else if value < min2 { min2 = value }
	}
	product1 := max1 * max2 * max3
	product2 := max1 * min1 * min2
	return max(product1, product2)
}
