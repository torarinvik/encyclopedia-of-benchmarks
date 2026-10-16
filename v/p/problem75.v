module problem75

const max_limit = 1500000

fn gcd_i64(left_input i64, right_input i64) i64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'problem75']
pub fn problem75(limit i64) i64 {
	if limit > max_limit { return -1 }
	if limit < 0 { return 0 }
	mut frequency := []u8{len: int(limit) + 1, init: 0}
	mut m := i64(2)
	for 2 * m * (m + 1) <= limit {
		mut n := (m % 2) + 1
		for n < m {
			if gcd_i64(m, n) == 1 {
				primitive_perimeter := 2 * m * (m + n)
				mut perimeter := primitive_perimeter
				for perimeter <= limit {
					index := int(perimeter)
					if frequency[index] < 2 { frequency[index]++ }
					perimeter += primitive_perimeter
				}
			}
			n += 2
		}
		m++
	}
	mut unique := i64(0)
	for perimeter in 1 .. int(limit) + 1 {
		if frequency[perimeter] == 1 { unique++ }
	}
	return unique
}
