package cdq_three_dimensional_dominance

import "core:c"

MAX_N :: 64
MAX_PARSEABLE_LENGTH :: 194

Point :: struct {
	x, y, z, multiplicity: i64,
	z_rank, original_index: int,
}

Workspace :: struct {
	points: [MAX_N]Point,
	original_group: [MAX_N]int,
	dominated: [MAX_N]i64,
	bit: [MAX_N + 1]i64,
	source_order, target_order: [MAX_N]int,
	z_values: [MAX_N]i64,
}

point_less :: proc(a, b: Point) -> bool {
	if a.x != b.x do return a.x < b.x
	if a.y != b.y do return a.y < b.y
	return a.z < b.z
}

same_coordinates :: proc(a, b: Point) -> bool {
	return a.x == b.x && a.y == b.y && a.z == b.z
}

bit_add :: proc(work: ^Workspace, start: int, delta: i64, limit: int) {
	index := start
	for index <= limit {
		work.bit[index] += delta
		index += index & -index
	}
}

bit_sum :: proc(work: ^Workspace, start: int) -> i64 {
	index := start
	total: i64 = 0
	for index > 0 {
		total += work.bit[index]
		index -= index & -index
	}
	return total
}

cdq :: proc(work: ^Workspace, left, right, group_count: int) {
	if left >= right do return
	middle := left + (right-left)/2
	cdq(work, left, middle, group_count)
	cdq(work, middle+1, right, group_count)

	source_cursor := left
	for target_position := middle+1; target_position <= right; target_position += 1 {
		target := work.source_order[target_position]
		for source_cursor <= middle {
			source := work.source_order[source_cursor]
			if work.points[source].y > work.points[target].y do break
			bit_add(work, work.points[source].z_rank, work.points[source].multiplicity, group_count)
			source_cursor += 1
		}
		work.dominated[target] += bit_sum(work, work.points[target].z_rank)
	}
	for i := left; i < source_cursor; i += 1 {
		source := work.source_order[i]
		bit_add(work, work.points[source].z_rank, -work.points[source].multiplicity, group_count)
	}

	left_cursor := left
	right_cursor := middle+1
	destination := left
	for left_cursor <= middle && right_cursor <= right {
		left_point := work.source_order[left_cursor]
		right_point := work.source_order[right_cursor]
		if work.points[left_point].y <= work.points[right_point].y {
			work.target_order[destination] = left_point
			left_cursor += 1
		} else {
			work.target_order[destination] = right_point
			right_cursor += 1
		}
		destination += 1
	}
	for left_cursor <= middle {
		work.target_order[destination] = work.source_order[left_cursor]
		left_cursor += 1
		destination += 1
	}
	for right_cursor <= right {
		work.target_order[destination] = work.source_order[right_cursor]
		right_cursor += 1
		destination += 1
	}
	for i := left; i <= right; i += 1 { work.source_order[i] = work.target_order[i] }
}

@(export)
cdq_three_dimensional_dominance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if int(length) != 1+3*n do return -1

	var work: Workspace
	for i := 0; i < n; i += 1 {
		x, y, z := input[1+3*i], input[2+3*i], input[3+3*i]
		if x < -1000 || x > 1000 || y < -1000 || y > 1000 || z < -1000 || z > 1000 do return -1
		work.points[i] = Point{x=x, y=y, z=z, multiplicity=1, original_index=i}
	}
	for i := 1; i < n; i += 1 {
		value := work.points[i]
		j := i
		for j > 0 && point_less(value, work.points[j-1]) {
			work.points[j] = work.points[j-1]
			j -= 1
		}
		work.points[j] = value
	}

	group_count := 0
	for i := 0; i < n; i += 1 {
		point := work.points[i]
		if group_count > 0 && same_coordinates(point, work.points[group_count-1]) {
			work.points[group_count-1].multiplicity += 1
			work.original_group[point.original_index] = group_count-1
		} else {
			work.points[group_count] = point
			work.points[group_count].multiplicity = 1
			work.original_group[point.original_index] = group_count
			group_count += 1
		}
	}

	for i := 0; i < group_count; i += 1 { work.z_values[i] = work.points[i].z }
	for i := 1; i < group_count; i += 1 {
		value := work.z_values[i]
		j := i
		for j > 0 && value < work.z_values[j-1] {
			work.z_values[j] = work.z_values[j-1]
			j -= 1
		}
		work.z_values[j] = value
	}
	z_count := 0
	for i := 0; i < group_count; i += 1 {
		value := work.z_values[i]
		if z_count == 0 || value != work.z_values[z_count-1] {
			work.z_values[z_count] = value
			z_count += 1
		}
	}
	for i := 0; i < group_count; i += 1 {
		low, high := 0, z_count
		for low < high {
			middle := low+(high-low)/2
			if work.z_values[middle] < work.points[i].z { low = middle+1 } else { high = middle }
		}
		work.points[i].z_rank = low+1
		work.source_order[i] = i
	}
	if group_count > 1 do cdq(&work, 0, group_count-1, z_count)
	result: i64 = 0
	for i := 0; i < n; i += 1 {
		group := work.original_group[i]
		count := work.dominated[group]+work.points[group].multiplicity-1
		result += i64(i+1)*count
	}
	return result
}
