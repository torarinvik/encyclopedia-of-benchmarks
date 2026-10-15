package sum_of_squares

import "core:c"

// Minimum number of perfect squares summing to value, using Lagrange's theorem.
@(export)
sum_of_squares :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 2_147_483_647 do return -1
	if value == 0 do return 0
	low := i64(1)
	high := value
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle <= value/middle { low = middle }
		else { high = middle }
	}
	root := low
	if root*root == value do return 1
	second := root
	for first := i64(1); first <= root; first += 1 {
		remainder := value - first*first
		for second*second > remainder { second -= 1 }
		if second*second == remainder do return 2
	}
	reduced := value
	for reduced % 4 == 0 { reduced /= 4 }
	if reduced % 8 == 7 do return 4
	return 3
}
