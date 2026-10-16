package problem78

Max_Modulus :: 1_000_000
Max_Index :: 55_374

positive_mod :: proc "contextless" (value, modulus: i64) -> i64 {
	remainder := value % modulus
	if remainder < 0 do remainder += modulus
	return remainder
}

@(export)
problem78 :: proc "c" (modulus: i64) -> i64 {
	if modulus < 1 || modulus > Max_Modulus do return -1
	partitions: [Max_Index + 1]u32
	partitions[0] = 1
	for n := 1; n <= Max_Index; n += 1 {
		value := i64(0)
		for j := i64(1);; j += 1 {
			first := (3 * j * j - j) / 2
			if first > i64(n) do break
			sign := i64(1)
			if j % 2 == 0 do sign = -1
			value = positive_mod(value + sign * i64(partitions[n - int(first)]), modulus)
			second := first + j
			if second > i64(n) do break
			value = positive_mod(value + sign * i64(partitions[n - int(second)]), modulus)
		}
		if value == 0 do return i64(n)
		partitions[n] = u32(value)
	}
	return -1
}
