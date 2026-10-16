module karatsuba

// Multiply bounded nonnegative operands with a three-product decimal split.
fn karatsuba_product(left i64, right i64) i64 {
	if left < 10 || right < 10 { return left * right }
	mut largest := left
	if right > largest { largest = right }
	mut digits := 1
	for mut remaining := largest; remaining >= 10; remaining /= 10 { digits++ }
	mut split := i64(1)
	for _ in 0 .. digits / 2 { split *= 10 }
	left_high, left_low := left / split, left % split
	right_high, right_low := right / split, right % split
	low_product := karatsuba_product(left_low, right_low)
	high_product := karatsuba_product(left_high, right_high)
	sum_product := karatsuba_product(left_high + left_low, right_high + right_low)
	return high_product * split * split + (sum_product - high_product - low_product) * split + low_product
}

@[export: 'karatsuba']
pub fn karatsuba(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	left, right := unsafe { input[0], input[1] }
	if left < 0 || left > 1000000 || right < 0 || right > 1000000 { return -1 }
	return karatsuba_product(left, right)
}
