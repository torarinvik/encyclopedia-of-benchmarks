const max_n = 64
const max_parseable_length = 194

struct Point {
	mut:
		x i64
		y i64
		z i64
		multiplicity i64
		z_rank int
		original_index int
}

struct Workspace {
	mut:
		points [max_n]Point
		original_group [max_n]int
		dominated [max_n]i64
		bit [max_n + 1]i64
		source_order [max_n]int
		target_order [max_n]int
		z_values [max_n]i64
}

fn point_less(a Point, b Point) bool {
	if a.x != b.x { return a.x < b.x }
	if a.y != b.y { return a.y < b.y }
	return a.z < b.z
}

fn same_coordinates(a Point, b Point) bool {
	return a.x == b.x && a.y == b.y && a.z == b.z
}

fn bit_add(mut work Workspace, start int, delta i64, limit int) {
	mut index := start
	for index <= limit {
		work.bit[index] += delta
		index += index & -index
	}
}

fn bit_sum(work Workspace, start int) i64 {
	mut index := start
	mut total := i64(0)
	for index > 0 {
		total += work.bit[index]
		index -= index & -index
	}
	return total
}

fn cdq(mut work Workspace, left int, right int, group_count int) {
	if left >= right { return }
	middle := left + (right-left)/2
	cdq(mut work, left, middle, group_count)
	cdq(mut work, middle+1, right, group_count)

	mut source_cursor := left
	for target_position in middle+1 .. right+1 {
		target := work.source_order[target_position]
		for source_cursor <= middle {
			source := work.source_order[source_cursor]
			if work.points[source].y > work.points[target].y { break }
			source_rank := work.points[source].z_rank
			source_weight := work.points[source].multiplicity
			bit_add(mut work, source_rank, source_weight, group_count)
			source_cursor++
		}
		target_rank := work.points[target].z_rank
		amount := bit_sum(work, target_rank)
		work.dominated[target] += amount
	}
	for i in left .. source_cursor {
		source := work.source_order[i]
		source_rank := work.points[source].z_rank
		source_weight := work.points[source].multiplicity
		bit_add(mut work, source_rank, -source_weight, group_count)
	}
	mut left_cursor := left
	mut right_cursor := middle+1
	mut destination := left
	for left_cursor <= middle && right_cursor <= right {
		left_point := work.source_order[left_cursor]
		right_point := work.source_order[right_cursor]
		if work.points[left_point].y <= work.points[right_point].y {
			work.target_order[destination] = left_point
			left_cursor++
		} else {
			work.target_order[destination] = right_point
			right_cursor++
		}
		destination++
	}
	for left_cursor <= middle {
		work.target_order[destination] = work.source_order[left_cursor]
		left_cursor++
		destination++
	}
	for right_cursor <= right {
		work.target_order[destination] = work.source_order[right_cursor]
		right_cursor++
		destination++
	}
	for i in left .. right+1 { work.source_order[i] = work.target_order[i] }
}

@[export: 'cdq_three_dimensional_dominance']
pub fn cdq_three_dimensional_dominance(input &i64, length usize) i64 {
	if length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(1+3*n) { return -1 }
		mut work := Workspace{}
		for i in 0 .. n {
			x := input[1+3*i]
			y := input[2+3*i]
			z := input[3+3*i]
			if x < -1000 || x > 1000 || y < -1000 || y > 1000 || z < -1000 || z > 1000 { return -1 }
			work.points[i] = Point{x: x, y: y, z: z, multiplicity: 1, original_index: i}
		}
		for i in 1 .. n {
			value := work.points[i]
			mut j := i
			for j > 0 && point_less(value, work.points[j-1]) {
				work.points[j] = work.points[j-1]
				j--
			}
			work.points[j] = value
		}
		mut group_count := 0
		for i in 0 .. n {
			point := work.points[i]
			if group_count > 0 && same_coordinates(point, work.points[group_count-1]) {
				work.points[group_count-1].multiplicity++
				work.original_group[point.original_index] = group_count-1
			} else {
				work.points[group_count] = point
				work.points[group_count].multiplicity = 1
				work.original_group[point.original_index] = group_count
				group_count++
			}
		}
		for i in 0 .. group_count { work.z_values[i] = work.points[i].z }
		for i in 1 .. group_count {
			value := work.z_values[i]
			mut j := i
			for j > 0 && value < work.z_values[j-1] {
				work.z_values[j] = work.z_values[j-1]
				j--
			}
			work.z_values[j] = value
		}
		mut z_count := 0
		for i in 0 .. group_count {
			value := work.z_values[i]
			if z_count == 0 || value != work.z_values[z_count-1] {
				work.z_values[z_count] = value
				z_count++
			}
		}
		for i in 0 .. group_count {
			mut low := 0
			mut high := z_count
			for low < high {
				middle := low+(high-low)/2
				if work.z_values[middle] < work.points[i].z { low = middle+1 } else { high = middle }
			}
			work.points[i].z_rank = low+1
			work.source_order[i] = i
		}
		if group_count > 1 { cdq(mut work, 0, group_count-1, z_count) }
		mut result := i64(0)
		for i in 0 .. n {
			group := work.original_group[i]
			count := work.dominated[group]+work.points[group].multiplicity-1
			result += i64(i+1)*count
		}
		return result
	}
}
