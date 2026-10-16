package problem94

@(export)
problem94 :: proc "c" (max_perimeter: i64) -> i64 {
	if max_perimeter < 0 || max_perimeter > 1_000_000_000 do return -1
	previous: i64 = 1
	value: i64 = 2
	perimeter_sum: i64 = 0
	index: i64 = 0
	perimeter: i64 = 0
	for perimeter <= max_perimeter {
		perimeter_sum += perimeter
		previous += 2 * value
		value += previous
		if index % 2 == 0 do perimeter = 2 * value + 2
		else do perimeter = 2 * value - 2
		index += 1
	}
	return perimeter_sum
}
