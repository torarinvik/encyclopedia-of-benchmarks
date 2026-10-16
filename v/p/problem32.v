module problem32

fn next_permutation(mut digits [9]int) bool {
	mut pivot := 7
	for pivot >= 0 && digits[pivot] >= digits[pivot + 1] { pivot-- }
	if pivot < 0 { return false }
	mut successor := 8
	for digits[successor] <= digits[pivot] { successor-- }
	digits[pivot], digits[successor] = digits[successor], digits[pivot]
	mut left := pivot + 1
	mut right := 8
	for left < right {
		digits[left], digits[right] = digits[right], digits[left]
		left++
		right--
	}
	return true
}

@[export: 'problem32']
pub fn problem32(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut digits := [9]int{}
	for i in 0..9 { digits[i] = i + 1 }
	mut seen := [10000]bool{}
	mut sum := i64(0)
	mut more := true
	for more {
		product := digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8]
		two_digit := digits[0] * 10 + digits[1]
		three_digit := digits[2] * 100 + digits[3] * 10 + digits[4]
		four_digit := digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4]
		if two_digit * three_digit == product || digits[0] * four_digit == product {
			if !seen[product] {
				seen[product] = true
				sum += i64(product)
			}
		}
		more = next_permutation(mut digits)
	}
	return sum
}
