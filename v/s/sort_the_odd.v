module sort_the_odd

@[export: 'sort_the_odd_benchmark']
pub fn sort_the_odd_benchmark(input &i64, length usize) i64 {
	if length > 256 || (unsafe { input == nil } && length > 0) { return -1 }

	mut odds := []i64{}
	for i in 0 .. int(length) {
		value := input[i]
		if value < -1_000_000 || value > 1_000_000 { return -1 }
		if value % 2 != 0 { odds << value }
	}
	odds.sort()

	mut odd_index := 0
	mut checksum := i64(0)
	for i in 0 .. int(length) {
		mut value := input[i]
		if value % 2 != 0 {
			value = odds[odd_index]
			odd_index++
		}
		checksum += i64(i + 1) * (value + 1_000_001)
	}
	return checksum
}
