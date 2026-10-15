package figurate_number

is_triangular :: proc(n: i64) -> bool {
	i := i64(0)
	for i <= n {
		term := i * (i + 1) / 2
		if term == n do return true
		if term > n do return false
		i += 1
	}
	return false
}

is_tetrahedral :: proc(n: i64) -> bool {
	i := i64(1)
	for i <= n {
		term := i * (i + 1) * (i + 2) / 6
		if term == n do return true
		if term > n do return false
		i += 1
	}
	return false
}

is_pentatope :: proc(n: i64) -> bool {
	i := i64(1)
	for i <= n {
		term := i * (i + 1) * (i + 2) * (i + 3) / 24
		if term == n do return true
		if term > n do return false
		i += 1
	}
	return false
}

@(export)
figurate_number :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 1_000_000 do return -1
	result := i64(0)
	if is_triangular(n) do result += 1
	if is_tetrahedral(n) do result += 2
	if is_pentatope(n) do result += 4
	return result
}
