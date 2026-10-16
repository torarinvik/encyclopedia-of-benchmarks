module problem203

fn is_squarefree(number i64) bool {
	mut copy := number
	mut divisor := i64(2)
	for divisor * divisor <= copy {
		mut multiplicity := 0
		for copy % divisor == 0 { copy /= divisor; multiplicity++ }
		if multiplicity >= 2 { return false }
		divisor++
	}
	return true
}

@[export: 'problem203']
pub fn problem203(depth i64) i64 {
	if depth > 51 { return -1 }
	mut row := [51]i64{}
	mut values := [1326]i64{}
	row[0] = 1
	values[0] = 1
	mut count := 1
	mut row_length := 1
	for _ in 2 .. int(depth) + 1 {
		row[row_length] = 1
		mut col := row_length - 1
		for col > 0 { row[col] += row[col - 1]; col-- }
		row[0] = 1
		row_length++
		for col in 0 .. row_length { values[count] = row[col]; count++ }
	}
	for i in 1 .. count {
		value := values[i]
		mut j := i
		for j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j-- }
		values[j] = value
	}
	mut total := i64(0)
	for i in 0 .. count {
		if i > 0 && values[i] == values[i - 1] { continue }
		if is_squarefree(values[i]) { total += values[i] }
	}
	return total
}
