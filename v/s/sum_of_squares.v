module sum_of_squares

// Minimum number of perfect squares summing to value, using Lagrange's theorem.
@[export: 'sum_of_squares']
pub fn sum_of_squares(value i64) i64 {
	if value < 0 || value > 2_147_483_647 { return -1 }
	if value == 0 { return 0 }
	mut low := i64(1)
	mut high := value
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle <= value / middle { low = middle }
		else { high = middle }
	}
	root := low
	if root * root == value { return 1 }
	mut second := root
	for first := i64(1); first <= root; first++ {
		remainder := value - first * first
		for second * second > remainder { second-- }
		if second * second == remainder { return 2 }
	}
	mut reduced := value
	for reduced % 4 == 0 { reduced /= 4 }
	if reduced % 8 == 7 { return 4 }
	return 3
}
