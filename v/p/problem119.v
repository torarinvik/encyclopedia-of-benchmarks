module problem119

fn digit_sum(mut value i64) i64 {
	mut sum := i64(0)
	for value > 0 { sum += value % 10; value /= 10 }
	return sum
}

@[export: 'problem119']
pub fn problem119(index i64) i64 {
	if index < 1 || index > 30 { return -1 }
	mut values := [10000]i64{}
	mut count := 0
	for base := i64(2); base < 100; base++ {
		mut value := base * base
		for exponent := 2; exponent < 100; exponent++ {
			if digit_sum(value) == base { values[count] = value; count++ }
			if value > 9223372036854775807 / base { break }
			value *= base
		}
	}
	for i in 1 .. count {
		value := values[i]
		mut j := i
		for j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j-- }
		values[j] = value
	}
	return values[int(index - 1)]
}
