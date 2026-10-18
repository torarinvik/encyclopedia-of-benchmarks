struct Point {
	x f64
	y f64
}

struct QuadNode {
	center_x f64
	center_y f64
	half_width f64
	point_count int
	point_indices [8]int
	children [4]int
	divided bool
}

struct Context {
	nodes [3073]QuadNode
	node_count int
	points [64]Point
	capacity int
	query_indices [64]int
	query_count int
	query_x f64
	query_y f64
	query_half_width f64
}

fn contains(node QuadNode, point Point) bool {
	return point.x >= node.center_x - node.half_width && point.x <= node.center_x + node.half_width &&
		point.y >= node.center_y - node.half_width && point.y <= node.center_y + node.half_width
}

fn intersects(node QuadNode, context &Context) bool {
	return context.query_x - context.query_half_width <= node.center_x + node.half_width &&
		context.query_x + context.query_half_width >= node.center_x - node.half_width &&
		context.query_y - context.query_half_width <= node.center_y + node.half_width &&
		context.query_y + context.query_half_width >= node.center_y - node.half_width
}

fn subdivide(mut context Context, node_index int) {
	child_half := context.nodes[node_index].half_width / 2.0
	cx := context.nodes[node_index].center_x
	cy := context.nodes[node_index].center_y
	child_x := [4]f64{cx - child_half, cx + child_half, cx - child_half, cx + child_half}
	child_y := [4]f64{cy + child_half, cy + child_half, cy - child_half, cy - child_half}
	for child in 0 .. 4 {
		index := context.node_count
		context.node_count++
		context.nodes[index] = QuadNode{}
		context.nodes[index].center_x = child_x[child]
		context.nodes[index].center_y = child_y[child]
		context.nodes[index].half_width = child_half
		context.nodes[node_index].children[child] = index
	}
	context.nodes[node_index].divided = true
}

fn insert_point(mut context Context, node_index int, point_index int) bool {
	node := context.nodes[node_index]
	point := context.points[point_index]
	if !contains(node, point) { return false }
	if node.point_count < context.capacity {
		context.nodes[node_index].point_indices[node.point_count] = point_index
		context.nodes[node_index].point_count++
		return true
	}
	if !node.divided { subdivide(mut context, node_index) }
	for child in 0 .. 4 {
		child_index := context.nodes[node_index].children[child]
		if insert_point(mut context, child_index, point_index) { return true }
	}
	return false
}

fn query_node(mut context Context, node_index int) {
	node := context.nodes[node_index]
	if !intersects(node, context) { return }
	left := context.query_x - context.query_half_width
	right := context.query_x + context.query_half_width
	bottom := context.query_y - context.query_half_width
	top := context.query_y + context.query_half_width
	for index in 0 .. node.point_count {
		point_index := node.point_indices[index]
		point := context.points[point_index]
		if point.x >= left && point.x <= right && point.y >= bottom && point.y <= top {
			context.query_indices[context.query_count] = point_index
			context.query_count++
		}
	}
	if node.divided {
		for child in 0 .. 4 { query_node(mut context, node.children[child]) }
	}
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (byte * 8)) & 0xff) }
}

@[export: 'quad_tree']
pub fn quad_tree(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 8 || input_length > 137 { return -1 }
		if input[0] < -2048 || input[0] > 2048 || input[1] < -2048 || input[1] > 2048 ||
			input[2] < 1 || input[2] > 1024 || input[3] < 1 || input[3] > 8 || input[4] < 0 || input[4] > 64 { return -1 }
		point_count := int(input[4])
		if input_length != usize(8 + 2 * point_count) { return -1 }
		query_offset := 5 + 2 * point_count
		if input[query_offset] < -8192 || input[query_offset] > 8192 ||
			input[query_offset + 1] < -8192 || input[query_offset + 1] > 8192 ||
			input[query_offset + 2] < 0 || input[query_offset + 2] > 8192 { return -1 }

		mut context := Context{}
		context.node_count = 1
		context.capacity = int(input[3])
		context.query_x = f64(input[query_offset])
		context.query_y = f64(input[query_offset + 1])
		context.query_half_width = f64(input[query_offset + 2])
		context.nodes[0].center_x = f64(input[0])
		context.nodes[0].center_y = f64(input[1])
		context.nodes[0].half_width = f64(input[2])
		for point in 0 .. point_count {
			x := input[5 + 2 * point]
			y := input[6 + 2 * point]
			if x < -8192 || x > 8192 || y < -8192 || y > 8192 { return -1 }
			for earlier in 0 .. point {
				if input[5 + 2 * earlier] == x && input[6 + 2 * earlier] == y { return -1 }
			}
			context.points[point] = Point{f64(x), f64(y)}
		}

		mut words := [194]i64{}
		words[0] = i64(point_count)
		for point in 0 .. point_count { words[1 + point] = if insert_point(mut context, 0, point) { 1 } else { 0 } }
		query_node(mut context, 0)
		word_count := 2 + point_count + 2 * context.query_count
		words[1 + point_count] = i64(context.query_count)
		for index in 0 .. context.query_count {
			point := context.points[context.query_indices[index]]
			words[2 + point_count + 2 * index] = i64(point.x)
			words[3 + point_count + 2 * index] = i64(point.y)
		}
		output_bytes := word_count * 8
		if output_bytes > 1552 { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. word_count { write_i64_le(mut output, index * 8, words[index]) }
		return i64(output_bytes)
	}
}
