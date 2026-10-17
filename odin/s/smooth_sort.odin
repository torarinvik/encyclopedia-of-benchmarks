package smooth_sort

import "core:c"

MAX_N :: 512
MAX_VALID_INPUT_LENGTH :: c.size_t(513)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(514)
MAX_VALUE :: i64(1_000_000)
OFFSET :: i64(1_000_001)
LEONARDO :: [16]int{1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973}

trailing_zeros :: proc "contextless" (value: u64) -> int {
	count := 0
	current := value
	for (current & 1) == 0 { current >>= 1; count += 1 }
	return count
}

sift :: proc "contextless" (values: [^]i64, order_arg, root_arg: int) {
	order, root := order_arg, root_arg
	value := values[root]
	for order > 1 {
		right := root-1
		left := root-1-LEONARDO[order-2]
		if !(value < values[left]) && !(value < values[right]) { break }
		if !(values[left] < values[right]) { values[root] = values[left]; root = left; order -= 1
		} else { values[root] = values[right]; root = right; order -= 2 }
	}
	values[root] = value
}

trinkle :: proc "contextless" (values: [^]i64, p_arg: u64, order_arg, root_arg: int, trusty_arg: bool) {
	p, order, root, trusty := p_arg, order_arg, root_arg, trusty_arg
	value := values[root]
	for p != 1 {
		stepson := root-LEONARDO[order]
		if !(value < values[stepson]) { break }
		if !trusty && order > 1 {
			right := root-1
			left := root-1-LEONARDO[order-2]
			if !(values[right] < values[stepson]) || !(values[left] < values[stepson]) { break }
		}
		values[root] = values[stepson]
		root = stepson
		mask := p & ~u64(1)
		shift := trailing_zeros(mask)
		p >>= shift
		order += shift
		trusty = false
	}
	if !trusty { values[root] = value; sift(values, order, root) }
}

smoothsort :: proc "contextless" (values: [^]i64, length: int) {
	if length < 2 do return
	last := length-1
	p := u64(1)
	pshift, head := 1, 0
	for head < last {
		if (p & 3) == 3 {
			sift(values, pshift, head)
			p >>= 2
			pshift += 2
		} else {
			if LEONARDO[pshift-1] >= last-head { trinkle(values, p, pshift, head, false)
			} else { sift(values, pshift, head) }
			if pshift == 1 { p <<= 1; pshift = 0
			} else { p <<= pshift-1; pshift = 1 }
		}
		p |= 1
		head += 1
	}
	trinkle(values, p, pshift, head, false)
	for pshift != 1 || p != 1 {
		if pshift <= 1 {
			mask := p & ~u64(1)
			shift := trailing_zeros(mask)
			p >>= shift
			pshift += shift
		} else {
			p <<= 2
			p ^= 7
			pshift -= 2
			trinkle(values, p>>1, pshift+1, head-LEONARDO[pshift]-1, true)
			trinkle(values, p, pshift, head-1, true)
		}
		head -= 1
	}
}

smooth_sort_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALID_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_N do return -1
	count := int(input[0])
	if length != c.size_t(count+1) do return -1
	var values: [MAX_N]i64
	for index in 0 ..< count {
		value := input[index+1]
		if value < -MAX_VALUE || value > MAX_VALUE do return -1
		values[index] = value
	}
	smoothsort(&values[0], count)
	checksum := i64(0)
	for index in 0 ..< count { checksum += i64(index+1)*(values[index]+OFFSET) }
	return checksum
}
