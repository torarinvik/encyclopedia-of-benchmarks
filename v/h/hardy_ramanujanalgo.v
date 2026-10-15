module hardy_ramanujanalgo

@[export: 'hardy_ramanujanalgo']
pub fn hardy_ramanujanalgo(value i64) i64 {
	if value < 1 || value > 2_147_483_647 { return -1 }

	mut remaining := value
	mut count := i64(0)
	if remaining % 2 == 0 { count++ }
	for remaining % 2 == 0 {
		remaining /= 2
	}

	mut factor := i64(3)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			count++
			for remaining % factor == 0 {
				remaining /= factor
			}
		}
		factor += 2
	}
	if remaining > 2 { count++ }
	return count
}
