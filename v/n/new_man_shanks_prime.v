module new_man_shanks_prime

const max_index = i64(25)
const int32_min_value = i64(-2147483648)
const int32_max_value = i64(2147483647)

// Compare the source recurrence term a[n] with expected; this is not primality testing.
@[export: 'new_man_shanks_prime']
pub fn new_man_shanks_prime(n i64, expected i64) i64 {
	if n < 1 || n > max_index || expected < int32_min_value || expected > int32_max_value { return -1 }
	mut previous_previous := i32(1)
	mut previous := i32(1)
	if n == 1 { return if expected == i64(previous) { 1 } else { 0 } }
	for index := i64(2); index <= n; index++ {
		current := 2 * previous + previous_previous
		previous_previous = previous
		previous = current
	}
	return if expected == i64(previous) { 1 } else { 0 }
}
