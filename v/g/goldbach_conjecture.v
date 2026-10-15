module goldbach_conjecture

fn goldbach_is_prime(value i64) bool {
	if value == 2 { return true }
	if value < 2 || value % 2 == 0 { return false }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

@[export: 'goldbach_conjecture']
pub fn goldbach_conjecture(number i64, output &u8, output_capacity usize) i64 {
	if number < 4 || number > 4096 || number % 2 != 0 { return -1 }
	if output_capacity < 8 { return -2 }
	mut first := i64(0)
	for first <= number / 2 {
		second := number - first
		if goldbach_is_prime(first) && goldbach_is_prime(second) {
			pair := [2]u32{u32(first), u32(second)}
			for j in 0 .. 2 {
				for b in 0 .. 4 {
					unsafe { output[4 * j + b] = u8((pair[j] >> (8 * b)) & 0xff) }
				}
			}
			return 8
		}
		first++
	}
	return -1
}
