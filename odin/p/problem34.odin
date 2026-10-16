package problem34

DIGIT_FACTORIALS: [10]i64 = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880}

@(export)
problem34 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	total: i64 = 0
	for number := i64(3); number <= 2_540_160; number += 1 {
		remaining := number
		digit_sum: i64 = 0
		for remaining > 0 {
			digit_sum += DIGIT_FACTORIALS[remaining % 10]
			remaining /= 10
		}
		if digit_sum == number { total += number }
	}
	return total
}
