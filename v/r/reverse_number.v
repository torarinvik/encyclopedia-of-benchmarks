module reverse_number

const max_input = i64(1000000000)

@[export: 'reverse_number']
pub fn reverse_number(number i64) i64 {
	if number < 0 || number > max_input { return -1 }
	mut current := number
	mut reversed := i64(0)
	for current > 0 {
		reversed = reversed * 10 + current % 10
		current /= 10
	}
	return reversed
}
