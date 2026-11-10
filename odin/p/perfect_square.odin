package perfect_square

// Exact perfect-square check using bounded integer binary search.
@(export)
perfect_square :: proc "c" (input: i64) -> i64 {
	if input < 0 do return 0
	if input < 2 do return 1
	number := u64(input)
	if ((u64(0x0213) >> (number & 15)) & 1) == 0 do return 0
	low := u64(1)
	root_limit := u64(65535) if number <= 0xffffffff else u64(3037000499)
	high := min(number / 2, root_limit)
	for low <= high {
		middle := (low + high) >> 1
		square := middle * middle
		if square == number do return 1
		if square < number {
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return 0
}
