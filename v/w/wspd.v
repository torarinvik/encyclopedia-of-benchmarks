module wspd

import math

const max_points = 8
const max_nodes = 15
const max_pairs = 28
const max_output_bytes = 456

struct WspdNode {
	left int
	right int
	count int
	mask u64
	cx f64
	cy f64
	radius f64
}

struct WspdContext {
	x [max_points]i64
	y [max_points]i64
	nodes [max_nodes]WspdNode
	left_masks [max_pairs]u64
	right_masks [max_pairs]u64
	mut:
	next_node int
	pair_count int
	point_count int
	separation int
	overflow bool
}

fn point_less(ctx &WspdContext, a int, b int, axis int) bool {
	unsafe {
		a0, b0 := ctx.x[a], ctx.x[b]
		a1, b1 := ctx.y[a], ctx.y[b]
		if axis == 1 { a0, b0 = ctx.y[a], ctx.y[b]; a1, b1 = ctx.x[a], ctx.x[b] }
		return a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)))
	}
}

fn build_node(mut ctx &WspdContext, mask u64) int {
	unsafe {
		id := ctx.next_node
		ctx.next_node++
		ctx.nodes[id].left = -1
		ctx.nodes[id].right = -1
		ctx.nodes[id].mask = mask
		mut members := [max_points]int{}
		mut used := 0
		mut min_x, mut max_x, mut min_y, mut max_y := i64(0), i64(0), i64(0), i64(0)
		for i in 0 .. ctx.point_count {
			if mask & (u64(1) << i) != 0 {
				if used == 0 { min_x, max_x, min_y, max_y = ctx.x[i], ctx.x[i], ctx.y[i], ctx.y[i] }
				else { if ctx.x[i] < min_x { min_x = ctx.x[i] }; if ctx.x[i] > max_x { max_x = ctx.x[i] }; if ctx.y[i] < min_y { min_y = ctx.y[i] }; if ctx.y[i] > max_y { max_y = ctx.y[i] } }
				members[used] = i
				used++
			}
		}
		ctx.nodes[id].count = used
		ctx.nodes[id].cx = (f64(min_x) + f64(max_x)) / 2.0
		ctx.nodes[id].cy = (f64(min_y) + f64(max_y)) / 2.0
		hx := (f64(max_x) - f64(min_x)) / 2.0
		hy := (f64(max_y) - f64(min_y)) / 2.0
		ctx.nodes[id].radius = math.sqrt(hx*hx + hy*hy)
		if used == 1 { return id }
		axis := 0
		if max_y-min_y > max_x-min_x { axis = 1 }
		for i := 1; i < used; i++ {
			value := members[i]
			mut j := i
			for j > 0 && point_less(ctx, value, members[j-1], axis) { members[j] = members[j-1]; j-- }
			members[j] = value
		}
		mut left_mask := u64(0)
		mut right_mask := u64(0)
		middle := used / 2
		for i in 0 .. used { if i < middle { left_mask |= u64(1) << members[i] } else { right_mask |= u64(1) << members[i] } }
		left := build_node(mut ctx, left_mask)
		right := build_node(mut ctx, right_mask)
		ctx.nodes[id].left, ctx.nodes[id].right = left, right
		return id
	}
}

fn well_separated(ctx &WspdContext, a int, b int) bool {
	unsafe {
		first, second := ctx.nodes[a], ctx.nodes[b]
		radius := if first.radius > second.radius { first.radius } else { second.radius }
		dx, dy := first.cx-second.cx, first.cy-second.cy
		return math.sqrt(dx*dx+dy*dy)-2.0*radius > f64(ctx.separation)*radius
	}
}

fn cross_nodes(mut ctx &WspdContext, a int, b int) {
	unsafe {
		if ctx.overflow { return }
		if well_separated(ctx, a, b) {
			if ctx.pair_count >= max_pairs { ctx.overflow = true; return }
			ctx.left_masks[ctx.pair_count] = ctx.nodes[a].mask
			ctx.right_masks[ctx.pair_count] = ctx.nodes[b].mask
			ctx.pair_count++
			return
		}
		if ctx.nodes[a].radius > ctx.nodes[b].radius {
			cross_nodes(mut ctx, ctx.nodes[a].left, b)
			cross_nodes(mut ctx, ctx.nodes[a].right, b)
		} else {
			cross_nodes(mut ctx, a, ctx.nodes[b].left)
			cross_nodes(mut ctx, a, ctx.nodes[b].right)
		}
	}
}

fn visit_node(mut ctx &WspdContext, id int) {
	unsafe {
		left, right := ctx.nodes[id].left, ctx.nodes[id].right
		if left < 0 { return }
		visit_node(mut ctx, left)
		visit_node(mut ctx, right)
		cross_nodes(mut ctx, left, right)
	}
}

fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'wspd']
pub fn wspd(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > 18 || values[0] < 1 || values[0] > i64(max_points) || values[1] < 1 || values[1] > 8 || length != usize(2+2*values[0]) { return -1 }
		mut ctx := WspdContext{}
		ctx.point_count, ctx.separation = int(values[0]), int(values[1])
		for i in 0 .. ctx.point_count {
			x, y := values[2+2*i], values[3+2*i]
			if x < -1000 || x > 1000 || y < -1000 || y > 1000 { return -1 }
			for j in 0 .. i { if ctx.x[j] == x && ctx.y[j] == y { return -1 } }
			ctx.x[i], ctx.y[i] = x, y
		}
		root := build_node(mut ctx, (u64(1) << ctx.point_count)-1)
		visit_node(mut ctx, root)
		if ctx.overflow { return -2 }
		required := 8+16*ctx.pair_count
		mut staged := [max_output_bytes]u8{}
		put_i64(mut &staged[0], 0, i64(ctx.pair_count))
		for i in 0 .. ctx.pair_count {
			put_i64(mut &staged[0], 8+16*i, i64(ctx.left_masks[i]))
			put_i64(mut &staged[0], 16+16*i, i64(ctx.right_masks[i]))
		}
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
