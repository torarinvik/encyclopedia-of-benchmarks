module problem39

fn integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(1415)
	for high - low > 1 {
		middle := (low + high) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

@[export: 'problem39']
pub fn problem39(limit i64) i64 {
	if limit < 12 || limit > 1000 { return -1 }
	mut counts := [1001]i64{}
	mut first_order := [1001]i64{}
	mut next_order := i64(1)
	for base in 1 .. int(limit + 1) {
		for perpendicular in base .. int(limit + 1) {
			square_sum := i64(base) * i64(base) + i64(perpendicular) * i64(perpendicular)
			hypotenuse := integer_sqrt(square_sum)
			if hypotenuse * hypotenuse != square_sum { continue }
			perimeter := i64(base + perpendicular) + hypotenuse
			if perimeter > limit { continue }
			index := int(perimeter)
			if counts[index] == 0 { first_order[index] = next_order; next_order++ }
			counts[index]++
		}
	}
	mut best_perimeter := i64(-1)
	mut best_count := i64(0)
	mut best_order := i64(9223372036854775807)
	for perimeter in 1 .. int(limit + 1) {
		index := int(perimeter)
		if counts[index] > 0 && (counts[index] > best_count ||
			(counts[index] == best_count && first_order[index] < best_order)) {
			best_perimeter = i64(perimeter)
			best_count = counts[index]
			best_order = first_order[index]
		}
	}
	return best_perimeter
}
