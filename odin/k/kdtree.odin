package kdtree

import "core:c"

MAX_INITIAL_POINTS :: 64
MAX_POINTS :: 128
MAX_OPERATIONS :: 256
MAX_VALID_INPUT_LENGTH :: c.size_t(898)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(899)
MIN_COORDINATE :: i64(-1000)
MAX_COORDINATE :: i64(1000)
CHECKSUM_OFFSET :: i64(1001)
NONE :: -1

Point :: struct { x, y: i64 }
Node :: struct { point: Point, axis: int, left, right: int }

coordinate :: proc "contextless" (point: Point, axis: int) -> i64 { if axis == 0 { return point.x }; return point.y }

build :: proc "contextless" (points: [^]Point, start, length, depth: int, nodes: [^]Node, node_count: ^int) -> int {
	if length == 0 do return NONE
	axis := depth%2
	for index := start+1; index < start+length; index += 1 {
		value := points[index]
		position := index
		for position > start && coordinate(points[position-1], axis) > coordinate(value, axis) { points[position] = points[position-1]; position -= 1 }
		points[position] = value
	}
	median := length/2
	root := node_count^
	node_count^ += 1
	nodes[root] = Node{point = points[start+median], axis = axis, left = NONE, right = NONE}
	left := build(points, start, median, depth+1, nodes, node_count)
	right := build(points, start+median+1, length-median-1, depth+1, nodes, node_count)
	nodes[root].left, nodes[root].right = left, right
	return root
}

insert :: proc "contextless" (nodes: [^]Node, node_count: ^int, root: int, point: Point, depth: int) -> int {
	if root == NONE {
		index := node_count^
		node_count^ += 1
		nodes[index] = Node{point = point, axis = depth%2, left = NONE, right = NONE}
		return index
	}
	axis := nodes[root].axis
	if coordinate(point, axis) < coordinate(nodes[root].point, axis) { nodes[root].left = insert(nodes, node_count, nodes[root].left, point, depth+1)
	} else { nodes[root].right = insert(nodes, node_count, nodes[root].right, point, depth+1) }
	return root
}

search :: proc "contextless" (nodes: [^]Node, root: int, point: Point) -> bool {
	if root == NONE do return false
	if nodes[root].point.x == point.x && nodes[root].point.y == point.y do return true
	axis := nodes[root].axis
	if coordinate(point, axis) < coordinate(nodes[root].point, axis) { return search(nodes, nodes[root].left, point) }
	return search(nodes, nodes[root].right, point)
}

distance_squared :: proc "contextless" (left, right: Point) -> i64 {
	dx, dy := left.x-right.x, left.y-right.y
	return dx*dx+dy*dy
}

nearest :: proc "contextless" (nodes: [^]Node, root: int, query: Point, best_arg: int) -> int {
	if root == NONE do return best_arg
	if nodes[root].point.x == query.x && nodes[root].point.y == query.y do return root
	point, axis := nodes[root].point, nodes[root].axis
	distance := distance_squared(point, query)
	dx, dy := point.x-query.x, point.y-query.y
	distance_except_axis := dy*dy
	if axis == 1 { distance_except_axis = dx*dx }
	best := best_arg
	if distance < distance_squared(nodes[best].point, query) { best = root }
	query_left := coordinate(query, axis) < coordinate(point, axis)
	near, far := nodes[root].right, nodes[root].left
	if query_left { near, far = nodes[root].left, nodes[root].right }
	best = nearest(nodes, near, query, best)
	if distance_except_axis < distance_squared(nodes[best].point, query) { best = nearest(nodes, far, query, best) }
	return best
}

kdtree_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	initial_value := input[0]
	if initial_value < 0 || initial_value > MAX_INITIAL_POINTS do return -1
	initial_count := int(initial_value)
	operation_count_index := 1+2*initial_count
	if c.size_t(operation_count_index) >= length do return -1
	operation_value := input[operation_count_index]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	if length != c.size_t(operation_count_index+1+3*operation_count) || length > MAX_VALID_INPUT_LENGTH do return -1

	var points: [MAX_INITIAL_POINTS]Point
	for index in 0 ..< initial_count {
		point := Point{x = input[1+2*index], y = input[2+2*index]}
		if point.x < MIN_COORDINATE || point.x > MAX_COORDINATE || point.y < MIN_COORDINATE || point.y > MAX_COORDINATE do return -1
		for previous in 0 ..< index { if points[previous].x == point.x || points[previous].y == point.y do return -1 }
		points[index] = point
	}

	var nodes: [MAX_POINTS]Node
	point_count, root := 0, NONE
	if initial_count > 0 { root = build(&points[0], 0, initial_count, 0, &nodes[0], &point_count) }
	checksum := i64(0)
	operations_start := operation_count_index+1
	for operation in 0 ..< operation_count {
		position := operations_start+3*operation
		opcode, first, second := input[position], input[position+1], input[position+2]
		result := i64(0)
		if opcode == 0 || opcode == 1 || opcode == 4 {
			if first < MIN_COORDINATE || first > MAX_COORDINATE || second < MIN_COORDINATE || second > MAX_COORDINATE do return -1
			point := Point{x = first, y = second}
			if opcode == 0 {
				if point_count >= MAX_POINTS do return -1
				for index in 0 ..< point_count { if nodes[index].point.x == first || nodes[index].point.y == second do return -1 }
				root = insert(&nodes[0], &point_count, root, point, 0)
				continue
			} else if opcode == 1 {
				if search(&nodes[0], root, point) { result = 1 }
			} else {
				if root == NONE do return -1
				closest := nearest(&nodes[0], root, point, root)
				result = distance_squared(nodes[closest].point, point)
			}
		} else if opcode == 2 || opcode == 3 {
			if first < 0 || first > 1 || second != 0 || root == NONE do return -1
			axis := int(first)
			result = coordinate(nodes[0].point, axis)
			for index in 1 ..< point_count {
				value := coordinate(nodes[index].point, axis)
				if (opcode == 2 && value < result) || (opcode == 3 && value > result) { result = value }
			}
		} else { return -1 }
		checksum += i64(operation+1)*(result+CHECKSUM_OFFSET)
	}
	return checksum
}
