module problem23

const max_limit = 28_123

@[export: 'problem23']
pub fn problem23(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	bound := int(limit)
	mut proper_divisor_sums := [max_limit + 1]i64{}
	mut abundant := [max_limit + 1]bool{}
	mut representable := [max_limit + 1]bool{}

	mut divisor := 1
	for divisor <= bound / 2 {
		mut multiple := 2 * divisor
		for multiple <= bound {
			proper_divisor_sums[multiple] += i64(divisor)
			multiple += divisor
		}
		divisor++
	}
	mut value := 12
	for value <= bound {
		abundant[value] = proper_divisor_sums[value] > i64(value)
		value++
	}
	mut left := 12
	for left <= bound {
		if abundant[left] {
			mut right := left
			for right <= bound - left {
				if abundant[right] { representable[left + right] = true }
				right++
			}
		}
		left++
	}

	mut total := i64(0)
	value = 1
	for value <= bound {
		if !representable[value] { total += i64(value) }
		value++
	}
	return total
}
