module kdtree

const max_initial_points = 64
const max_points = 128
const max_operations = 256
const max_valid_input_length = 898
const max_parseable_input_length = 899
const min_coordinate = i64(-1000)
const max_coordinate = i64(1000)
const checksum_offset = i64(1001)
const none = -1

struct Point { x i64; y i64 }

struct Node {
	point Point
	axis int
	mut:
	left int = none
	right int = none
}

fn coordinate(point Point, axis int) i64 { return if axis == 0 { point.x } else { point.y } }

fn build(mut points []Point, start int, length int, depth int, mut nodes []Node, mut node_count int) int {
	if length == 0 { return none }
	axis := depth % 2
	for index := start + 1; index < start + length; index++ {
		value := points[index]
		mut position := index
		for position > start && coordinate(points[position - 1], axis) > coordinate(value, axis) {
			points[position] = points[position - 1]
			position--
		}
		points[position] = value
	}
	median := length / 2
	root := node_count
	node_count++
	nodes[root] = Node{ point: points[start + median], axis: axis, left: none, right: none }
	left := build(mut points, start, median, depth + 1, mut nodes, mut node_count)
	right := build(mut points, start + median + 1, length - median - 1, depth + 1, mut nodes, mut node_count)
	nodes[root].left = left
	nodes[root].right = right
	return root
}

fn insert(mut nodes []Node, mut node_count int, root int, point Point, depth int) int {
	if root == none {
		index := node_count
		node_count++
		nodes[index] = Node{ point: point, axis: depth % 2, left: none, right: none }
		return index
	}
	axis := nodes[root].axis
	if coordinate(point, axis) < coordinate(nodes[root].point, axis) {
		nodes[root].left = insert(mut nodes, mut node_count, nodes[root].left, point, depth + 1)
	} else {
		nodes[root].right = insert(mut nodes, mut node_count, nodes[root].right, point, depth + 1)
	}
	return root
}

fn search(nodes []Node, root int, point Point) bool {
	if root == none { return false }
	if nodes[root].point.x == point.x && nodes[root].point.y == point.y { return true }
	axis := nodes[root].axis
	if coordinate(point, axis) < coordinate(nodes[root].point, axis) { return search(nodes, nodes[root].left, point) }
	return search(nodes, nodes[root].right, point)
}

fn distance_squared(left Point, right Point) i64 {
	dx, dy := left.x - right.x, left.y - right.y
	return dx * dx + dy * dy
}

fn nearest(nodes []Node, root int, query Point, best_arg int) int {
	if root == none { return best_arg }
	if nodes[root].point.x == query.x && nodes[root].point.y == query.y { return root }
	point, axis := nodes[root].point, nodes[root].axis
	distance := distance_squared(point, query)
	dx, dy := point.x - query.x, point.y - query.y
	distance_except_axis := if axis == 0 { dy * dy } else { dx * dx }
	mut best := best_arg
	if distance < distance_squared(nodes[best].point, query) { best = root }
	query_left := coordinate(query, axis) < coordinate(point, axis)
	mut near, mut far := nodes[root].right, nodes[root].left
	if query_left { near, far = nodes[root].left, nodes[root].right }
	best = nearest(nodes, near, query, best)
	if distance_except_axis < distance_squared(nodes[best].point, query) { best = nearest(nodes, far, query, best) }
	return best
}

@[export: 'kdtree_benchmark']
pub fn kdtree_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } { return -1 }
	if length < 2 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_initial_points { return -1 }
		initial_count := int(input[0])
		operation_count_index := 1 + 2 * initial_count
		if usize(operation_count_index) >= length { return -1 }
		operation_count_value := input[operation_count_index]
		if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		operation_count := int(operation_count_value)
		if length != usize(operation_count_index + 1 + 3 * operation_count) || length > usize(max_valid_input_length) { return -1 }

		mut points := [max_initial_points]Point{}
		for index in 0 .. initial_count {
			point := Point{ x: input[1 + 2 * index], y: input[2 + 2 * index] }
			if point.x < min_coordinate || point.x > max_coordinate || point.y < min_coordinate || point.y > max_coordinate { return -1 }
			for previous in 0 .. index { if points[previous].x == point.x || points[previous].y == point.y { return -1 } }
			points[index] = point
		}
		mut nodes := [max_points]Node{}
		mut point_count := 0
		mut root := none
		if initial_count > 0 { root = build(mut points[..], 0, initial_count, 0, mut nodes[..], mut point_count) }
		mut checksum := i64(0)
		operations_start := operation_count_index + 1
		for operation in 0 .. operation_count {
			position := operations_start + 3 * operation
			opcode, first, second := input[position], input[position + 1], input[position + 2]
			mut result := i64(0)
			if opcode == 0 || opcode == 1 || opcode == 4 {
				if first < min_coordinate || first > max_coordinate || second < min_coordinate || second > max_coordinate { return -1 }
				point := Point{ x: first, y: second }
				if opcode == 0 {
					if point_count >= max_points { return -1 }
					for index in 0 .. point_count { if nodes[index].point.x == first || nodes[index].point.y == second { return -1 } }
					root = insert(mut nodes[..], mut point_count, root, point, 0)
					continue
				} else if opcode == 1 {
					if search(nodes[..], root, point) { result = 1 }
				} else {
					if root == none { return -1 }
					closest := nearest(nodes[..], root, point, root)
					result = distance_squared(nodes[closest].point, point)
				}
			} else if opcode == 2 || opcode == 3 {
				if first < 0 || first > 1 || second != 0 || root == none { return -1 }
				axis := int(first)
				result = coordinate(nodes[0].point, axis)
				for index in 1 .. point_count {
					value := coordinate(nodes[index].point, axis)
					if (opcode == 2 && value < result) || (opcode == 3 && value > result) { result = value }
				}
			} else { return -1 }
			checksum += i64(operation + 1) * (result + checksum_offset)
		}
		return checksum
	}
}
