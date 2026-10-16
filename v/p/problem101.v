module problem101

fn question_function(n i64) i64 {
	mut term := i64(1)
	mut total := i64(0)
	for exponent in 0 .. 11 {
		if exponent % 2 == 0 { total += term } else { total -= term }
		term *= n
	}
	return total
}

@[export: 'problem101']
pub fn problem101(order i64) i64 {
	if order > 10 { return -1 }
	if order <= 0 { return 0 }
	mut data := [10]i64{}
	for i in 0 .. int(order) { data[i] = question_function(i64(i + 1)) }
	mut total_fit := i64(0)
	for k in 1 .. (int(order) + 1) {
		mut row := [10]i64{}
		mut differences := [10]i64{}
		for i in 0 .. k { row[i] = data[i] }
		differences[0] = row[0]
		for level in 1 .. k {
			for i in 0 .. (k - level) { row[i] = row[i + 1] - row[i] }
			differences[level] = row[0]
		}
		mut x := i64(1)
		for {
			mut prediction := i64(0)
			mut choose := i64(1)
			for j in 0 .. k {
				prediction += differences[j] * choose
				if j + 1 < k { choose = choose * (x - 1 - i64(j)) / i64(j + 1) }
			}
			if prediction != question_function(x) { total_fit += prediction; break }
			x++
		}
	}
	return total_fit
}
