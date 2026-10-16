package problem39

integer_sqrt :: proc(value: i64) -> i64 {
	low: i64 = 0
	high: i64 = 1415
	for high - low > 1 {
		middle := (low + high) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

@(export)
problem39 :: proc "c" (limit: i64) -> i64 {
	if limit < 12 || limit > 1000 { return -1 }
	counts: [1001]i64 = {}
	first_order: [1001]i64 = {}
	next_order: i64 = 1
	for base := i64(1); base <= limit; base += 1 {
		for perpendicular := base; perpendicular <= limit; perpendicular += 1 {
			square_sum := base * base + perpendicular * perpendicular
			hypotenuse := integer_sqrt(square_sum)
			if hypotenuse * hypotenuse != square_sum { continue }
			perimeter := base + perpendicular + hypotenuse
			if perimeter > limit { continue }
			if counts[perimeter] == 0 { first_order[perimeter] = next_order; next_order += 1 }
			counts[perimeter] += 1
		}
	}
	best_perimeter: i64 = -1
	best_count: i64 = 0
	best_order: i64 = 9223372036854775807
	for perimeter := i64(1); perimeter <= limit; perimeter += 1 {
		if counts[perimeter] > 0 && (counts[perimeter] > best_count ||
			(counts[perimeter] == best_count && first_order[perimeter] < best_order)) {
			best_perimeter = perimeter
			best_count = counts[perimeter]
			best_order = first_order[perimeter]
		}
	}
	return best_perimeter
}
