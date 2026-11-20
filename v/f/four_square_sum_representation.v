@[export: 'four_square_sum_representation']
pub fn four_square_sum_representation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		n := input[0]
		if n < 0 || n > 1024 { return -1 }

		mut a := int_sqrt(n)
		for a >= 0 {
			rem_a := n - a * a
			mut b_max := int_sqrt(rem_a)
			if b_max > a { b_max = a }
			mut b := b_max
			for b >= 0 {
				rem_b := rem_a - b * b
				mut c_max := int_sqrt(rem_b)
				if c_max > b { c_max = b }
				mut c := c_max
				for c >= 0 {
					rem_c := rem_b - c * c
					d := int_sqrt(rem_c)
					if d <= c && d * d == rem_c {
						return (((a * 33 + b) * 33 + c) * 33 + d)
					}
					c--
				}
				b--
			}
			a--
		}
		return -2
	}
}

fn int_sqrt(value i64) i64 {
	mut root := i64(0)
	for (root + 1) * (root + 1) <= value { root++ }
	return root
}
