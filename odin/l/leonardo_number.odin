package leonardo_number

// Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1.
@(export)
leonardo_number :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > 89 do return -1
	previous := i64(1)
	current := i64(1)
	for index := i64(2); index <= input; index += 1 {
		next := current + previous + 1
		previous = current
		current = next
	}
	return current
}
