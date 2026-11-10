module perfect_square

// Exact perfect-square check using bounded integer binary search.
@[export: 'perfect_square']
pub fn perfect_square(input i64) i64 {
	if input < 0 { return 0 }
	if input < 2 { return 1 }
	number := u64(input)
	if ((u64(0x0213) >> (number & 15)) & 1) == 0 { return 0 }
	mut low := u64(1)
	half := number / 2
	root_limit := if number <= u64(0xffffffff) { u64(65535) } else { u64(3037000499) }
	mut high := if half < root_limit { half } else { root_limit }
	for low <= high {
		middle := (low + high) >> 1
		square := middle * middle
		if square == number { return 1 }
		if square < number {
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return 0
}
