module problem94

@[export: 'problem94']
pub fn problem94(max_perimeter i64) i64 {
	if max_perimeter < 0 || max_perimeter > 1_000_000_000 { return -1 }
	mut previous := i64(1)
	mut value := i64(2)
	mut perimeter_sum := i64(0)
	mut index := i64(0)
	mut perimeter := i64(0)
	for perimeter <= max_perimeter {
		perimeter_sum += perimeter
		previous += 2 * value
		value += previous
		if index % 2 == 0 { perimeter = 2 * value + 2 }
		else { perimeter = 2 * value - 2 }
		index++
	}
	return perimeter_sum
}
