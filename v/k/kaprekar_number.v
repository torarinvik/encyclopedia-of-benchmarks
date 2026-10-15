module kaprekar_number

@[export: 'kaprekar_number']
pub fn kaprekar_number(number i64) i64 {
	if number < 1 { return 0 }
	if number > 2_000_000_000 { return -1 }
	if number == 1 { return 1 }
	square := number * number
	mut split := i64(10)
	for split <= square {
		right := square % split
		if right > 0 && square / split + right == number { return 1 }
		if split > square / 10 { break }
		split *= 10
	}
	return 0
}
