module smooth_sort

const max_n = 512
const max_valid_input_length = 513
const max_parseable_input_length = 514
const max_value = i64(1_000_000)
const offset = i64(1_000_001)
const leonardo = [1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973]!

fn trailing_zeros(value u64) int {
	mut current := value
	mut count := 0
	for (current & u64(1)) == 0 { current >>= 1; count++ }
	return count
}

fn sift(mut values []i64, order_arg int, root_arg int) {
	mut order, mut root := order_arg, root_arg
	value := values[root]
	for order > 1 {
		right := root - 1
		left := root - 1 - leonardo[order - 2]
		if !(value < values[left]) && !(value < values[right]) { break }
		if !(values[left] < values[right]) {
			values[root] = values[left]
			root = left
			order--
		} else {
			values[root] = values[right]
			root = right
			order -= 2
		}
	}
	values[root] = value
}

fn trinkle(mut values []i64, p_arg u64, order_arg int, root_arg int, trusty_arg bool) {
	mut p, mut order, mut root, mut trusty := p_arg, order_arg, root_arg, trusty_arg
	value := values[root]
	for p != 1 {
		stepson := root - leonardo[order]
		if !(value < values[stepson]) { break }
		if !trusty && order > 1 {
			right := root - 1
			left := root - 1 - leonardo[order - 2]
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
	if !trusty {
		values[root] = value
		sift(mut values, order, root)
	}
}

fn smoothsort(mut values []i64, length int) {
	if length < 2 { return }
	last := length - 1
	mut p := u64(1)
	mut pshift, mut head := 1, 0
	for head < last {
		if (p & u64(3)) == u64(3) {
			sift(mut values, pshift, head)
			p >>= 2
			pshift += 2
		} else {
			if leonardo[pshift - 1] >= last - head { trinkle(mut values, p, pshift, head, false) }
			else { sift(mut values, pshift, head) }
			if pshift == 1 { p <<= 1; pshift = 0 }
			else { p <<= pshift - 1; pshift = 1 }
		}
		p |= 1
		head++
	}
	trinkle(mut values, p, pshift, head, false)
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
			trinkle(mut values, p >> 1, pshift + 1, head - leonardo[pshift] - 1, true)
			trinkle(mut values, p, pshift, head - 1, true)
		}
		head--
	}
}

@[export: 'smooth_sort_benchmark']
pub fn smooth_sort_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } { return -1 }
	if length < 1 || length > usize(max_parseable_input_length) || length > usize(max_valid_input_length) { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_n { return -1 }
		count := int(input[0])
		if length != usize(count + 1) { return -1 }
		mut values := [max_n]i64{}
		for index in 0 .. count {
			value := input[index + 1]
			if value < -max_value || value > max_value { return -1 }
			values[index] = value
		}
		smoothsort(mut values[..], count)
		mut checksum := i64(0)
		for index in 0 .. count { checksum += i64(index + 1) * (values[index] + offset) }
		return checksum
	}
}
