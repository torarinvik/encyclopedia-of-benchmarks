module problem78

const max_modulus = 1000000
const max_index = 55374

fn positive_mod(value i64, modulus i64) i64 {
	mut remainder := value % modulus
	if remainder < 0 { remainder += modulus }
	return remainder
}

@[export: 'problem78']
pub fn problem78(modulus i64) i64 {
	if modulus < 1 || modulus > max_modulus { return -1 }
	mut partitions := [max_index + 1]u32{}
	partitions[0] = 1
	for n in 1 .. max_index + 1 {
		mut value := i64(0)
		mut j := i64(1)
		for {
			first := (3 * j * j - j) / 2
			if first > i64(n) { break }
			sign := if j % 2 == 0 { i64(-1) } else { i64(1) }
			value = positive_mod(value + sign * i64(partitions[n - int(first)]), modulus)
			second := first + j
			if second > i64(n) { break }
			value = positive_mod(value + sign * i64(partitions[n - int(second)]), modulus)
			j++
		}
		if value == 0 { return i64(n) }
		partitions[n] = u32(value)
	}
	return -1
}
