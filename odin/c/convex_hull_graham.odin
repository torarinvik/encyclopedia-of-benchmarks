package convex_hull_graham

import "core:c"

MAX_POINTS :: 64

cross :: proc(a, b, c: int, values: [^]i64) -> i64 {
	ax, ay := values[2*a], values[2*a+1]
	bx, by := values[2*b], values[2*b+1]
	cx, cy := values[2*c], values[2*c+1]
	return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
}

orientation :: proc(a, b, c: int, values: [^]i64) -> int {
	turn := cross(a, b, c, values)
	if turn < 0 do return 1
	if turn > 0 do return -1
	return 0
}

sort_indices :: proc(items, scratch: [^]int, begin, end: int, values: [^]i64) {
	if end - begin < 2 do return
	middle := begin + (end - begin) / 2
	sort_indices(items, scratch, begin, middle, values)
	sort_indices(items, scratch, middle, end, values)
	left, right, out := begin, middle, begin
	for left < middle && right < end {
		if values[2*items[right]] < values[2*items[left]] { scratch[out] = items[right]; right += 1 }
		else { scratch[out] = items[left]; left += 1 }
		out += 1
	}
	for left < middle { scratch[out] = items[left]; left += 1; out += 1 }
	for right < end { scratch[out] = items[right]; right += 1; out += 1 }
	for index := begin; index < end; index += 1 { items[index] = scratch[index] }
}

put_index :: proc(output: [^]u8, position, id: int) {
	value := u32(id)
	for byte := 0; byte < 4; byte += 1 { output[4*position+byte] = u8((value >> u32(8*byte)) & 255) }
}

@(export)
convex_hull_graham :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length % 2 != 0 || length > c.size_t(2*MAX_POINTS) do return -1
	count := int(length / 2)
	if count < 3 || count > MAX_POINTS do return -1
	for index := 0; index < 2*count; index += 1 { if values[index] < -2000 || values[index] > 2000 do return -1 }

	order, scratch, upper, lower: [MAX_POINTS]int
	for index := 0; index < count; index += 1 { order[index] = index }
	sort_indices(&order[0], &scratch[0], 0, count, values)
	for index := 1; index < count; index += 1 { if values[2*order[index-1]] == values[2*order[index]] do return -1 }
	for index := 1; index < count-1; index += 1 { if cross(order[0], order[index], order[count-1], values) == 0 do return -1 }

	upper_count, lower_count := 1, 1
	upper[0] = 0; lower[0] = 0
	for index := 1; index < count; index += 1 {
		turn := orientation(order[0], order[index], order[count-1], values)
		if index == count-1 || turn != -1 {
			for upper_count >= 2 && orientation(order[upper[upper_count-2]], order[upper[upper_count-1]], order[index], values) == -1 { upper_count -= 1 }
			upper[upper_count] = index; upper_count += 1
		}
		if index == count-1 || turn != 1 {
			for lower_count >= 2 && orientation(order[lower[lower_count-2]], order[lower[lower_count-1]], order[index], values) == 1 { lower_count -= 1 }
			lower[lower_count] = index; lower_count += 1
		}
	}
	hull_count := upper_count - 2 + lower_count
	if output == nil || capacity < c.size_t(4*hull_count) do return -2
	written := 0
	for index := 1; index < upper_count-1; index += 1 { put_index(output, written, order[upper[index]]); written += 1 }
	for index := lower_count; index > 0; index -= 1 { put_index(output, written, order[lower[index-1]]); written += 1 }
	return i64(hull_count)
}
