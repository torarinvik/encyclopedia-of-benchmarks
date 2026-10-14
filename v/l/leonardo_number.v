module leonardo_number

// Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1.
@[export: 'leonardo_number']
pub fn leonardo_number(input i64) i64 {
	if input < 0 || input > 89 { return -1 }
	mut previous := i64(1)
	mut current := i64(1)
	mut index := i64(2)
	for index <= input {
		next := current + previous + 1
		previous = current
		current = next
		index++
	}
	return current
}
