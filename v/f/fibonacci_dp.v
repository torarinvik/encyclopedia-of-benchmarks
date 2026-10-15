module fibonacci_dp

// Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
@[export: 'fibonacci_dp']
pub fn fibonacci_dp(n i64) i64 {
	if n < 0 || n > 46 {
		return -1
	}

	mut table := [47]i64{}
	table[0] = 0
	table[1] = 1
	mut index := 2
	for index <= int(n) {
		table[index] = table[index - 1] + table[index - 2]
		index++
	}
	return table[int(n)]
}
