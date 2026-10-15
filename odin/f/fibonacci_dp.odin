package fibonacci_dp

// Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
@(export)
fibonacci_dp :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 46 do return -1

	table: [47]i64
	table[0] = 0
	table[1] = 1
	for index := 2; index <= int(n); index += 1 {
		table[index] = table[index - 1] + table[index - 2]
	}
	return table[int(n)]
}
