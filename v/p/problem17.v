module problem17

@[export: 'problem17']
pub fn problem17(limit i64) i64 {
	if limit < 0 || limit > 1000 { return -1 }
	ones := [20]i64{0, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8}
	tens := [10]i64{0, 0, 6, 6, 5, 5, 5, 7, 6, 6}
	mut total := i64(0)
	for value := i64(1); value <= limit; value++ {
		if value == 1000 {
			total += ones[1] + 8
			continue
		}
		mut remainder := value
		if value >= 100 {
			total += ones[int(value / 100)] + 7
			remainder = value % 100
			if remainder != 0 { total += 3 }
		}
		if remainder < 20 {
			total += ones[int(remainder)]
		} else {
			total += tens[int(remainder / 10)] + ones[int(remainder % 10)]
		}
	}
	return total
}
