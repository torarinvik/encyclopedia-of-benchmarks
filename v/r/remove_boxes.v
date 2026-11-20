module main

const max_boxes = 18
const max_parseable_length = max_boxes + 2
const max_memo = max_boxes * max_boxes * (max_boxes + 1)

fn remove_boxes_solve(left int, right int, carry int, colors []i64, counts []int, mut memo []i64) i64 {
	if left > right {
		return 0
	}
	index := (left * max_boxes + right) * (max_boxes + 1) + carry
	if memo[index] >= 0 {
		return memo[index]
	}
	attached := counts[left] + carry
	mut best := i64(attached * attached) + remove_boxes_solve(left + 1, right, 0, colors, counts, mut memo)
	for later in left + 1 .. right + 1 {
		if colors[later] == colors[left] {
			joined := remove_boxes_solve(left + 1, later - 1, 0, colors, counts, mut memo)
				+ remove_boxes_solve(later, right, attached, colors, counts, mut memo)
			if joined > best {
				best = joined
			}
		}
	}
	memo[index] = best
	return best
}

@[export: 'remove_boxes']
pub fn remove_boxes(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_parseable_length {
			return -1
		}
		if values[0] < 0 || values[0] > max_boxes {
			return -1
		}
		n := int(values[0])
		if length != usize(n + 1) {
			return -1
		}
		mut colors := []i64{len: max_boxes, init: 0}
		mut counts := []int{len: max_boxes, init: 0}
		mut groups := 0
		for index in 0 .. n {
			color := values[index + 1]
			if color < 0 || color > 7 {
				return -1
			}
			if groups > 0 && colors[groups - 1] == color {
				counts[groups - 1]++
			} else {
				colors[groups] = color
				counts[groups] = 1
				groups++
			}
		}
		if groups == 0 {
			return 0
		}
		mut memo := []i64{len: max_memo, init: -1}
		return remove_boxes_solve(0, groups - 1, 0, colors, counts, mut memo)
	}
}
