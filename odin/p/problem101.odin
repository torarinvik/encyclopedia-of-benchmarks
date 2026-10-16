package problem101

question_function :: proc(n: i64) -> i64 {
	term := i64(1)
	total := i64(0)
	for exponent := 0; exponent <= 10; exponent += 1 {
		if exponent % 2 == 0 { total += term } else { total -= term }
		term *= n
	}
	return total
}

@(export)
problem101 :: proc "c" (order: i64) -> i64 {
	if order > 10 do return -1
	if order <= 0 do return 0
	data: [10]i64
	for i := 0; i < int(order); i += 1 { data[i] = question_function(i64(i + 1)) }
	total_fit := i64(0)
	for k := 1; k <= int(order); k += 1 {
		row: [10]i64
		differences: [10]i64
		for i := 0; i < k; i += 1 { row[i] = data[i] }
		differences[0] = row[0]
		for level := 1; level < k; level += 1 {
			for i := 0; i < k - level; i += 1 { row[i] = row[i + 1] - row[i] }
			differences[level] = row[0]
		}
		x := i64(1)
		for {
			prediction := i64(0)
			choose := i64(1)
			for j := 0; j < k; j += 1 {
				prediction += differences[j] * choose
				if j + 1 < k { choose = choose * (x - 1 - i64(j)) / i64(j + 1) }
			}
			if prediction != question_function(x) { total_fit += prediction; break }
			x += 1
		}
	}
	return total_fit
}
