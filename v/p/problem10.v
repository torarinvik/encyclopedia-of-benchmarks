module problem10

@[export: 'problem10']
pub fn problem10(limit i64) i64 {
	if limit < 0 || limit > 2_000_000 { return -1 }
	mut composite := [1_000_000]bool{}
	odd_count := int(limit / 2)
	mut total := if limit > 2 { i64(2) } else { i64(0) }
	mut prime := 3
	for prime * prime < int(limit) {
		if !composite[prime / 2] {
			mut index := prime * prime / 2
			for index < odd_count {
				composite[index] = true
				index += prime
			}
		}
		prime += 2
	}
	for index := 1; index < odd_count; index++ {
		if !composite[index] { total += i64(2 * index + 1) }
	}
	return total
}
