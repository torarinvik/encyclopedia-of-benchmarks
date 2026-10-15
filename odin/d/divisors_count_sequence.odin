package divisors_count_sequence

MAX_INDEX :: i64(9999)

@(export, link_name="divisors_count_sequence")
divisors_count_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > MAX_INDEX do return -1
	n := index + 1
	if n == 1 do return 1
	count: i64 = 2
	for k: i64 = 2; k < n; k += 1 {
		if n % k == 0 do count += 1
	}
	return count
}

main :: proc() {}
