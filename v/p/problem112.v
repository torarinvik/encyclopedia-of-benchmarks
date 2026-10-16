module problem112

fn is_bouncy(mut value i64) bool {
	mut increasing := false
	mut decreasing := false
	mut previous := value % 10
	value /= 10
	for value > 0 {
		digit := value % 10
		if digit < previous { increasing = true }
		if digit > previous { decreasing = true }
		previous = digit
		value /= 10
	}
	return increasing && decreasing
}

@[export: 'problem112']
pub fn problem112(percent i64) i64 {
	if percent < 1 || percent > 99 { return -1 }
	mut bouncy := i64(0)
	mut n := i64(1)
	for {
		if is_bouncy(n) { bouncy++ }
		if bouncy * 100 >= percent * n { return n }
		n++
	}
}
