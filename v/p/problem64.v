module problem64

const max_limit = 10000

fn integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := value + 1
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle <= value / middle { low = middle } else { high = middle }
	}
	return low
}

fn period_length(value i64, root i64) i64 {
	mut numerator := i64(0)
	mut denominator := i64(1)
	mut coefficient := root
	mut period := i64(0)
	for {
		numerator = denominator * coefficient - numerator
		denominator = (value - numerator * numerator) / denominator
		coefficient = (root + numerator) / denominator
		period++
		if coefficient == 2 * root { break }
	}
	return period
}

@[export: 'problem64']
pub fn problem64(inclusive_limit i64) i64 {
	if inclusive_limit < 0 || inclusive_limit > max_limit { return -1 }
	mut count := i64(0)
	for value := i64(2); value <= inclusive_limit; value++ {
		root := integer_sqrt(value)
		if root * root != value && period_length(value, root) % 2 == 1 { count++ }
	}
	return count
}
