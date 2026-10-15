package minimum_steps_to_one

MAX_N :: 10_000

@(export)
minimum_steps_to_one :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > MAX_N do return -1
	table: [MAX_N + 1]i64
	for index := 0; index <= int(n); index += 1 do table[index] = n + 1
	table[1] = 0
	for i := 1; i < int(n); i += 1 {
		candidate := table[i] + 1
		if table[i + 1] > candidate do table[i + 1] = candidate
		if i * 2 <= int(n) && table[i * 2] > candidate do table[i * 2] = candidate
		if i * 3 <= int(n) && table[i * 3] > candidate do table[i * 3] = candidate
	}
	return table[int(n)]
}
