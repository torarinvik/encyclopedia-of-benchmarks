module convex_hull_graham

const max_points = 64

fn cross(a int, b int, c int, values &i64) i64 {
	unsafe {
		ax, ay := values[2*a], values[2*a+1]
		bx, by := values[2*b], values[2*b+1]
		cx, cy := values[2*c], values[2*c+1]
		return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
	}
}

fn orientation(a int, b int, c int, values &i64) int {
	turn := cross(a,b,c,values)
	if turn < 0 { return 1 }
	if turn > 0 { return -1 }
	return 0
}

fn sort_indices(mut items []int, mut scratch []int, begin int, ending int, values &i64) {
	if ending - begin < 2 { return }
	middle := begin + (ending - begin) / 2
	sort_indices(mut items, mut scratch, begin, middle, values)
	sort_indices(mut items, mut scratch, middle, ending, values)
	mut left := begin
	mut right := middle
	mut out := begin
	for left < middle && right < ending {
		right_first := unsafe { values[2*items[right]] < values[2*items[left]] }
		if right_first { scratch[out] = items[right]; right++ } else { scratch[out] = items[left]; left++ }
		out++
	}
	for left < middle { scratch[out] = items[left]; left++; out++ }
	for right < ending { scratch[out] = items[right]; right++; out++ }
	for index in begin .. ending { items[index] = scratch[index] }
}

fn put_index(mut output &u8, position int, id int) {
	value := u32(id)
	unsafe { for byte in 0 .. 4 { output[4*position+byte] = u8((value >> (8*byte)) & 255) } }
}

@[export: 'convex_hull_graham']
pub fn convex_hull_graham(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length % 2 != 0 || length > usize(2*max_points) { return -1 }
	count := int(length / 2)
	if count < 3 || count > max_points { return -1 }
	for index in 0 .. 2*count {
		coordinate := unsafe { values[index] }
		if coordinate < -2000 || coordinate > 2000 { return -1 }
	}
	mut order := []int{len: count}
	mut scratch := []int{len: count}
	mut upper := []int{len: count}
	mut lower := []int{len: count}
	for index in 0 .. count { order[index] = index }
	sort_indices(mut order, mut scratch, 0, count, values)
	for index in 1 .. count {
		if unsafe { values[2*order[index-1]] == values[2*order[index]] } { return -1 }
	}
	for index in 1 .. (count-1) {
		if cross(order[0], order[index], order[count-1], values) == 0 { return -1 }
	}

	mut upper_count := 1
	mut lower_count := 1
	upper[0] = 0
	lower[0] = 0
	for index in 1 .. count {
		turn := orientation(order[0], order[index], order[count-1], values)
		if index == count-1 || turn != -1 {
			for upper_count >= 2 && orientation(order[upper[upper_count-2]], order[upper[upper_count-1]], order[index], values) == -1 { upper_count-- }
			upper[upper_count] = index
			upper_count++
		}
		if index == count-1 || turn != 1 {
			for lower_count >= 2 && orientation(order[lower[lower_count-2]], order[lower[lower_count-1]], order[index], values) == 1 { lower_count-- }
			lower[lower_count] = index
			lower_count++
		}
	}
	hull_count := upper_count - 2 + lower_count
	if unsafe { output == nil } || capacity < usize(4*hull_count) { return -2 }
	mut written := 0
	for index in 1 .. (upper_count-1) { put_index(mut output, written, order[upper[index]]); written++ }
	mut index := lower_count
	for index > 0 { index--; put_index(mut output, written, order[lower[index]]); written++ }
	return i64(hull_count)
}
