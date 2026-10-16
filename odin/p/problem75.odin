package problem75

MAX_LIMIT :: 1_500_000

gcd_i64 :: proc(left_input, right_input: i64) -> i64 {
	left := left_input
	right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@(export)
problem75 :: proc "c" (limit: i64) -> i64 {
	if limit > MAX_LIMIT do return -1
	if limit < 0 do return 0
	frequency := make([]u8, int(limit) + 1)
	defer delete(frequency)
	for m := i64(2); 2 * m * (m + 1) <= limit; m += 1 {
		for n := (m % 2) + 1; n < m; n += 2 {
			if gcd_i64(m, n) != 1 do continue
			primitive_perimeter := 2 * m * (m + n)
			for perimeter := primitive_perimeter; perimeter <= limit; perimeter += primitive_perimeter {
				if frequency[int(perimeter)] < 2 { frequency[int(perimeter)] += 1 }
			}
		}
	}
	unique := i64(0)
	for perimeter := 1; perimeter <= int(limit); perimeter += 1 {
		if frequency[perimeter] == 1 { unique += 1 }
	}
	return unique
}
