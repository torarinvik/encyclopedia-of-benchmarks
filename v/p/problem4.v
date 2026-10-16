module problem4

fn is_palindrome(value i64) bool {
	mut remaining := value
	mut reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return reversed == value
}

@[export: 'problem4']
pub fn problem4(digits i64) i64 {
	if digits < 1 || digits > 3 { return -1 }
	minimum := if digits == 1 { i64(1) } else if digits == 2 { i64(10) } else { i64(100) }
	maximum := if digits == 1 { i64(9) } else if digits == 2 { i64(99) } else { i64(999) }
	mut largest := i64(0)
	mut first := maximum
	for first >= minimum && first * maximum > largest {
		mut second := maximum
		for second >= first && first * second > largest {
			product := first * second
			if is_palindrome(product) { largest = product }
			second--
		}
		first--
	}
	return largest
}
