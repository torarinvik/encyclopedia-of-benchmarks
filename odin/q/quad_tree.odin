package quad_tree

import "core:c"

MAX_POINTS :: 64
MAX_CAPACITY :: 8
MAX_DEPTH :: 12
MAX_NODES :: 1 + 4 * MAX_POINTS * MAX_DEPTH
MAX_PARSEABLE_INPUT_LENGTH :: 137
MAX_OUTPUT_WORDS :: 194
MAX_OUTPUT_BYTES :: 1552

Point :: struct { x, y: f64 }
Quad_Node :: struct {
	center_x, center_y, half_width: f64,
	point_count: int,
	point_indices: [MAX_CAPACITY]int,
	children: [4]int,
	divided: bool,
}
Context :: struct {
	nodes: [MAX_NODES]Quad_Node,
	node_count: int,
	points: [MAX_POINTS]Point,
	capacity: int,
	query_indices: [MAX_POINTS]int,
	query_count: int,
	query_x, query_y, query_half_width: f64,
}

contains :: proc(node: Quad_Node, point: Point) -> bool {
	return point.x >= node.center_x-node.half_width && point.x <= node.center_x+node.half_width &&
		point.y >= node.center_y-node.half_width && point.y <= node.center_y+node.half_width
}

intersects :: proc(node: Quad_Node, context: ^Context) -> bool {
	return context.query_x-context.query_half_width <= node.center_x+node.half_width &&
		context.query_x+context.query_half_width >= node.center_x-node.half_width &&
		context.query_y-context.query_half_width <= node.center_y+node.half_width &&
		context.query_y+context.query_half_width >= node.center_y-node.half_width
}

subdivide :: proc(context: ^Context, node_index: int) {
	child_half := context.nodes[node_index].half_width / 2.0
	cx := context.nodes[node_index].center_x
	cy := context.nodes[node_index].center_y
	child_x := [4]f64{cx-child_half, cx+child_half, cx-child_half, cx+child_half}
	child_y := [4]f64{cy+child_half, cy+child_half, cy-child_half, cy-child_half}
	for child := 0; child < 4; child += 1 {
		index := context.node_count
		context.node_count += 1
		context.nodes[index] = {}
		context.nodes[index].center_x = child_x[child]
		context.nodes[index].center_y = child_y[child]
		context.nodes[index].half_width = child_half
		context.nodes[node_index].children[child] = index
	}
	context.nodes[node_index].divided = true
}

insert_point :: proc(context: ^Context, node_index, point_index: int) -> bool {
	node := context.nodes[node_index]
	point := context.points[point_index]
	if !contains(node, point) do return false
	if node.point_count < context.capacity {
		context.nodes[node_index].point_indices[node.point_count] = point_index
		context.nodes[node_index].point_count += 1
		return true
	}
	if !node.divided do subdivide(context, node_index)
	for child := 0; child < 4; child += 1 {
		child_index := context.nodes[node_index].children[child]
		if insert_point(context, child_index, point_index) do return true
	}
	return false
}

query_node :: proc(context: ^Context, node_index: int) {
	node := context.nodes[node_index]
	if !intersects(node, context) do return
	left := context.query_x-context.query_half_width
	right := context.query_x+context.query_half_width
	bottom := context.query_y-context.query_half_width
	top := context.query_y+context.query_half_width
	for index := 0; index < node.point_count; index += 1 {
		point_index := node.point_indices[index]
		point := context.points[point_index]
		if point.x >= left && point.x <= right && point.y >= bottom && point.y <= top {
			context.query_indices[context.query_count] = point_index
			context.query_count += 1
		}
	}
	if node.divided {
		for child := 0; child < 4; child += 1 { query_node(context, node.children[child]) }
	}
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (byte*8)) & 0xff) }
}

@(export)
quad_tree :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 8 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < -2048 || input[0] > 2048 || input[1] < -2048 || input[1] > 2048 ||
		input[2] < 1 || input[2] > 1024 || input[3] < 1 || input[3] > MAX_CAPACITY ||
		input[4] < 0 || input[4] > MAX_POINTS do return -1
	point_count := int(input[4])
	if int(input_length) != 8 + 2*point_count do return -1
	query_offset := 5 + 2*point_count
	if input[query_offset] < -8192 || input[query_offset] > 8192 ||
		input[query_offset+1] < -8192 || input[query_offset+1] > 8192 ||
		input[query_offset+2] < 0 || input[query_offset+2] > 8192 do return -1

	context: Context = {}
	context.node_count = 1
	context.capacity = int(input[3])
	context.query_x = f64(input[query_offset])
	context.query_y = f64(input[query_offset+1])
	context.query_half_width = f64(input[query_offset+2])
	context.nodes[0].center_x = f64(input[0])
	context.nodes[0].center_y = f64(input[1])
	context.nodes[0].half_width = f64(input[2])
	for point := 0; point < point_count; point += 1 {
		x := input[5+2*point]
		y := input[6+2*point]
		if x < -8192 || x > 8192 || y < -8192 || y > 8192 do return -1
		for earlier := 0; earlier < point; earlier += 1 {
			if input[5+2*earlier] == x && input[6+2*earlier] == y do return -1
		}
		context.points[point] = Point{f64(x), f64(y)}
	}

	words: [MAX_OUTPUT_WORDS]i64
	words[0] = i64(point_count)
	for point := 0; point < point_count; point += 1 {
		if insert_point(&context, 0, point) { words[1+point] = 1 }
	}
	query_node(&context, 0)
	word_count := 2 + point_count + 2*context.query_count
	words[1+point_count] = i64(context.query_count)
	for index := 0; index < context.query_count; index += 1 {
		point := context.points[context.query_indices[index]]
		words[2+point_count+2*index] = i64(point.x)
		words[3+point_count+2*index] = i64(point.y)
	}
	output_bytes := word_count * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < word_count; index += 1 { write_i64_le(output, index*8, words[index]) }
	return i64(output_bytes)
}
