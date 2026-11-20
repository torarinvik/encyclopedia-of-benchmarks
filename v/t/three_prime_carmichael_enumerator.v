module three_prime_carmichael_enumerator

const max_limit = i64(61)
const max_triples = 69
const max_output_bytes = 4 + 12 * max_triples

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value % 2 == 0 { return value == 2 }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

fn put_u32_le(mut output &u8, offset int, value u32) {
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((value >> (8 * byte)) & 255) }
	}
}

@[export: 'three_prime_carmichael_enumerator']
pub fn three_prime_carmichael_enumerator(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		limit := input[0]
		if limit < 2 || limit > max_limit { return -1 }

		mut staged := [max_output_bytes]u8{}
		mut count := 0
		mut position := 4
		mut p1 := i64(2)
		for p1 <= limit {
			if is_prime(p1) {
				mut h3 := i64(2)
				for h3 < p1 {
					g := h3 + p1
					mut d := i64(1)
					for d < g {
						if (g * (p1 - 1)) % d == 0 {
							square := (p1 * p1) % h3
							negative_square := if square == 0 { i64(0) } else { h3 - square }
							if negative_square == d % h3 {
								p2 := 1 + (p1 - 1) * g / d
                                if p2 > p1 && is_prime(p2) {
									p3 := 1 + p1 * p2 / h3
									if p3 > p2 && is_prime(p3) && (p2 * p3) % (p1 - 1) == 1 {
										if count >= max_triples { return -1 }
										put_u32_le(mut staged[0], position, u32(p1))
										put_u32_le(mut staged[0], position + 4, u32(p2))
										put_u32_le(mut staged[0], position + 8, u32(p3))
										position += 12
										count++
									}
								}
							}
						}
						d++
					}
					h3++
				}
			}
			p1++
		}

		put_u32_le(mut staged[0], 0, u32(count))
		if output == nil || capacity < usize(position) { return -2 }
		for offset in 0 .. position { output[offset] = staged[offset] }
		return i64(position)
	}
}
