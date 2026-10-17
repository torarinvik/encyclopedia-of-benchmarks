module main

import math

const invalid_result = i64(-1)
const output_error = i64(-2)

struct Node {
	point int
	left  int
	right int
}

struct SearchBest {
	distance f64
	point    int
}

struct PartitionBounds {
	smaller_to  int
	larger_from int
}

fn finite_integer_range(value f64, low f64, high f64) bool {
	return !math.is_nan(value) && !math.is_inf(value) && value >= low && value <= high && f64(i64(value)) == value
}

fn partition_five(mut ids []int, points [][]f64, from int, to int, axis int) int {
	middle := (from + to) / 2
	for i := from; i <= middle; i++ {
		mut minimum := i
		for j := i + 1; j <= to; j++ {
			if points[ids[j]][axis] < points[ids[minimum]][axis] { minimum = j }
		}
		ids[i], ids[minimum] = ids[minimum], ids[i]
	}
	return middle
}

fn select_kth(mut ids []int, points [][]f64, from int, to int, rank int, axis int) int

fn choose_median_of_medians(mut ids []int, points [][]f64, from int, to int, axis int) int {
	if to - from < 5 { return partition_five(mut ids, points, from, to, axis) }
	mut medians_to := from
	mut start := from
	for start <= to - 4 {
		median := partition_five(mut ids, points, start, start + 4, axis)
		ids[median], ids[medians_to] = ids[medians_to], ids[median]
		medians_to++
		start += 5
	}
	remainder := (to - from + 1) % 5
	if remainder == 0 {
		medians_to--
	} else {
		median := partition_five(mut ids, points, to - remainder + 1, to, axis)
		ids[median], ids[medians_to] = ids[medians_to], ids[median]
	}
	medians_count := medians_to - from + 1
	return select_kth(mut ids, points, from, medians_to, (medians_count + 1) / 2, axis)
}

fn partition_three_way(mut ids []int, points [][]f64, from int, to int, pivot_index int, axis int) PartitionBounds {
	pivot := points[ids[pivot_index]][axis]
	mut i := from
	mut j := from
	mut k := to
	for j <= k {
		value := points[ids[j]][axis]
		if value < pivot {
			ids[i], ids[j] = ids[j], ids[i]
			i++
			j++
		} else if pivot < value {
			ids[j], ids[k] = ids[k], ids[j]
			if k == 0 { break }
			k--
		} else { j++ }
	}
	return PartitionBounds{smaller_to: i - 1, larger_from: k + 1}
}

fn select_kth(mut ids []int, points [][]f64, from int, to int, rank int, axis int) int {
	mut first := from
	mut last := to
	mut target_rank := rank
	for first < last {
		pivot := choose_median_of_medians(mut ids, points, first, last, axis)
		bounds := partition_three_way(mut ids, points, first, last, pivot, axis)
		absolute_index := first + target_rank - 1
		if absolute_index <= bounds.smaller_to {
			last = bounds.smaller_to
		} else if absolute_index < bounds.larger_from {
			return absolute_index
		} else {
			target_rank -= bounds.larger_from - first
			first = bounds.larger_from
		}
	}
	return first
}

fn build_tree(points [][]f64, indices []int, dimension int, depth int, mut nodes []Node) int {
	if indices.len == 0 { return -1 }
	axis := depth % dimension
	mut ordered := indices.clone()
	middle := select_kth(mut ordered, points, 0, ordered.len - 1, (ordered.len + 1) / 2, axis)
	current := nodes.len
	nodes << Node{point: ordered[middle], left: -1, right: -1}
	left := build_tree(points, ordered[..middle], dimension, depth + 1, mut nodes)
	right := build_tree(points, ordered[middle + 1..], dimension, depth + 1, mut nodes)
	nodes[current].left = left
	nodes[current].right = right
	return current
}

fn search_tree(points [][]f64, nodes []Node, current int, axis int, dimension int,
	query []f64, mut best SearchBest) SearchBest {
	if current < 0 { return best }
	node := nodes[current]
	point := points[node.point]
	mut squared := 0.0
	for a in 0 .. dimension {
		delta := query[a] - point[a]
		squared += delta * delta
	}
	distance := math.sqrt(squared)
	if distance < best.distance { best = SearchBest{distance: distance, point: node.point} }
	go_left := query[axis] <= point[axis]
	near := if go_left { node.left } else { node.right }
	far := if go_left { node.right } else { node.left }
	next_axis := (axis + 1) % dimension
	best = search_tree(points, nodes, near, next_axis, dimension, query, mut best)
	if best.distance >= math.abs(point[axis] - query[axis]) {
		best = search_tree(points, nodes, far, next_axis, dimension, query, mut best)
	}
	return best
}

@[export: 'k_d_tree']
pub fn k_d_tree(input &f64, length usize, output &f64, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 2 || length > 51 { return invalid_result }
		if !finite_integer_range(input[0], 2.0, 3.0) { return invalid_result }
		dimension := int(input[0])
		if !finite_integer_range(input[1], 1.0, 15.0) { return invalid_result }
		count := int(input[1])
		if length != 2 + dimension * (count + 1) { return invalid_result }
		mut query := []f64{len: dimension}
		for axis in 0 .. dimension {
			value := input[2 + axis]
			if !finite_integer_range(value, -1000.0, 1000.0) { return invalid_result }
			query[axis] = value
		}
		mut points := [][]f64{len: count}
		for i in 0 .. count {
			points[i] = []f64{len: dimension}
			for axis in 0 .. dimension {
				value := input[2 + dimension + i * dimension + axis]
				if !finite_integer_range(value, -1000.0, 1000.0) { return invalid_result }
				points[i][axis] = value
			}
		}
		for axis in 0 .. dimension {
			for i in 0 .. count {
				for j in i + 1 .. count {
					if points[i][axis] == points[j][axis] { return invalid_result }
				}
			}
		}
		mut smallest := 1.0e300
		mut nearest_count := 0
		for point in points {
			mut squared := 0.0
			for axis in 0 .. dimension {
				delta := query[axis] - point[axis]
				squared += delta * delta
			}
			if squared < smallest { smallest = squared; nearest_count = 1 }
			else if squared == smallest { nearest_count++ }
		}
		if nearest_count != 1 { return invalid_result }
		output_length := dimension + 1
		if isnil(output) || capacity < output_length { return output_error }
		mut indices := []int{len: count}
		for i in 0 .. count { indices[i] = i }
		mut nodes := []Node{cap: count}
		root := build_tree(points, indices, dimension, 0, mut nodes)
		mut best := SearchBest{distance: 1.0e300, point: 0}
		best = search_tree(points, nodes, root, 0, dimension, query, mut best)
		output[0] = best.distance
		for axis in 0 .. dimension { output[axis + 1] = points[best.point][axis] }
		return i64(output_length)
	}
}
