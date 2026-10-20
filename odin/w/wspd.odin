package wspd

import "core:c"
import "core:math"

MAX_POINTS :: 8
MAX_NODES :: 15
MAX_PAIRS :: 28
MAX_OUTPUT_BYTES :: 456

Node :: struct { left, right, count: int, mask: u64, cx, cy, radius: f64 }
Context :: struct {
	x, y: [MAX_POINTS]i64,
	nodes: [MAX_NODES]Node,
	left_masks, right_masks: [MAX_PAIRS]u64,
	next_node, pair_count, point_count, separation: int,
	overflow: bool,
}

point_less :: proc "contextless" (ctx: ^Context, a, b, axis: int) -> bool {
	a0, b0 := ctx.x[a], ctx.x[b]
	a1, b1 := ctx.y[a], ctx.y[b]
	if axis == 1 { a0, b0 = ctx.y[a], ctx.y[b]; a1, b1 = ctx.x[a], ctx.x[b] }
	return a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)))
}

build_node :: proc "contextless" (ctx: ^Context, mask: u64) -> int {
	id := ctx.next_node; ctx.next_node += 1
	ctx.nodes[id].left = -1; ctx.nodes[id].right = -1; ctx.nodes[id].mask = mask
	members: [MAX_POINTS]int
	used := 0
	min_x, max_x, min_y, max_y: i64
	for i := 0; i < ctx.point_count; i += 1 {
		if mask & (u64(1) << i) != 0 {
			if used == 0 { min_x, max_x, min_y, max_y = ctx.x[i], ctx.x[i], ctx.y[i], ctx.y[i] }
			else { min_x = min(min_x, ctx.x[i]); max_x = max(max_x, ctx.x[i]); min_y = min(min_y, ctx.y[i]); max_y = max(max_y, ctx.y[i]) }
			members[used] = i; used += 1
		}
	}
	ctx.nodes[id].count = used
	ctx.nodes[id].cx = (f64(min_x) + f64(max_x)) / 2.0
	ctx.nodes[id].cy = (f64(min_y) + f64(max_y)) / 2.0
	hx := (f64(max_x) - f64(min_x)) / 2.0
	hy := (f64(max_y) - f64(min_y)) / 2.0
	ctx.nodes[id].radius = math.sqrt_f64(hx*hx + hy*hy)
	if used == 1 { return id }
	axis := 0
	if max_y-min_y > max_x-min_x { axis = 1 }
	for i := 1; i < used; i += 1 { value, j := members[i], i; for j > 0 && point_less(ctx, value, members[j-1], axis) { members[j] = members[j-1]; j -= 1 }; members[j] = value }
	middle := used / 2
	left_mask, right_mask: u64
	for i := 0; i < used; i += 1 { if i < middle { left_mask |= u64(1) << members[i] } else { right_mask |= u64(1) << members[i] } }
	left := build_node(ctx, left_mask); right := build_node(ctx, right_mask)
	ctx.nodes[id].left = left; ctx.nodes[id].right = right
	return id
}

well_separated :: proc "contextless" (ctx: ^Context, a, b: int) -> bool {
	x, y := ctx.nodes[a], ctx.nodes[b]
	radius := max(x.radius, y.radius)
	dx, dy := x.cx-y.cx, x.cy-y.cy
	return math.sqrt_f64(dx*dx+dy*dy)-2.0*radius > f64(ctx.separation)*radius
}

cross_nodes :: proc "contextless" (ctx: ^Context, a, b: int) {
	if ctx.overflow { return }
	if well_separated(ctx, a, b) {
		if ctx.pair_count >= MAX_PAIRS { ctx.overflow = true; return }
		ctx.left_masks[ctx.pair_count] = ctx.nodes[a].mask; ctx.right_masks[ctx.pair_count] = ctx.nodes[b].mask; ctx.pair_count += 1; return
	}
	if ctx.nodes[a].radius > ctx.nodes[b].radius { cross_nodes(ctx, ctx.nodes[a].left, b); cross_nodes(ctx, ctx.nodes[a].right, b) }
	else { cross_nodes(ctx, a, ctx.nodes[b].left); cross_nodes(ctx, a, ctx.nodes[b].right) }
}

visit_node :: proc "contextless" (ctx: ^Context, id: int) {
	left, right := ctx.nodes[id].left, ctx.nodes[id].right
	if left < 0 { return }
	visit_node(ctx, left); visit_node(ctx, right); cross_nodes(ctx, left, right)
}

put_i64 :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset+b] = u8(bits & 255); bits >>= 8 }
}

@(export)
wspd :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 18 || values[0] < 1 || values[0] > MAX_POINTS || values[1] < 1 || values[1] > 8 || length != c.size_t(2+2*values[0]) do return -1
	ctx := Context{point_count=int(values[0]), separation=int(values[1])}
	for i := 0; i < ctx.point_count; i += 1 {
		x, y := values[2+2*i], values[3+2*i]
		if x < -1000 || x > 1000 || y < -1000 || y > 1000 do return -1
		for j := 0; j < i; j += 1 { if ctx.x[j] == x && ctx.y[j] == y do return -1 }
		ctx.x[i], ctx.y[i] = x, y
	}
	root := build_node(&ctx, (u64(1) << ctx.point_count)-1)
	visit_node(&ctx, root)
	if ctx.overflow do return -2
	required := 8+16*ctx.pair_count
	staged: [MAX_OUTPUT_BYTES]u8
	put_i64(&staged[0], 0, i64(ctx.pair_count))
	for i := 0; i < ctx.pair_count; i += 1 { put_i64(&staged[0], 8+16*i, i64(ctx.left_masks[i])); put_i64(&staged[0], 16+16*i, i64(ctx.right_masks[i])) }
	if output == nil || capacity < c.size_t(required) do return -2
	for i := 0; i < required; i += 1 { output[i] = staged[i] }
	return i64(required)
}
