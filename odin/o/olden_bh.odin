package olden_bh

import "core:c"
import "core:math"

MIN_BODIES :: 2
MAX_BODIES :: 16
MAX_NODES :: 1024
MAX_DEPTH :: 16

Body :: struct { position: [3]f64, mass: f64 }
Cell :: struct { body: int, child: [8]int, mass: f64, center: [3]f64 }
Context :: struct { bodies: [MAX_BODIES]Body, cells: [MAX_NODES]Cell, used: int }

octant :: proc "contextless" (position, center: [^]f64) -> int {
	result := 0
	if position[0] >= center[0] do result |= 1
	if position[1] >= center[1] do result |= 2
	if position[2] >= center[2] do result |= 4
	return result
}

new_cell :: proc "contextless" (ctx: ^Context) -> int {
	if ctx.used >= MAX_NODES do return -1
	id := ctx.used; ctx.used += 1
	ctx.cells[id].body = -1
	for i := 0; i < 8; i += 1 { ctx.cells[id].child[i] = -1 }
	return id
}

insert_body :: proc "contextless" (ctx: ^Context, cell_index, body_index: int,
		center: [^]f64, half: f64, depth: int) -> bool {
	old_body := ctx.cells[cell_index].body
	if old_body == -1 { ctx.cells[cell_index].body = body_index; return true }
	if depth >= MAX_DEPTH do return false
	if old_body >= 0 do ctx.cells[cell_index].body = -2
	item_count := 1
	if old_body >= 0 do item_count = 2
	for item := 0; item < item_count; item += 1 {
		which_body := body_index
		if old_body >= 0 && item == 0 do which_body = old_body
		child := octant(&ctx.bodies[which_body].position[0], center)
		if ctx.cells[cell_index].child[child] < 0 {
			created := new_cell(ctx)
			if created < 0 do return false
			ctx.cells[cell_index].child[child] = created
		}
		var next_center: [3]f64
		for axis := 0; axis < 3; axis += 1 {
			direction := -half / 2.0
			if child & (1 << axis) != 0 do direction = half / 2.0
			next_center[axis] = center[axis] + direction
		}
		if !insert_body(ctx, ctx.cells[cell_index].child[child], which_body, &next_center[0], half / 2.0, depth + 1) do return false
	}
	return true
}

aggregate :: proc "contextless" (ctx: ^Context, cell_index: int) {
	body := ctx.cells[cell_index].body
	if body >= 0 {
		ctx.cells[cell_index].mass = ctx.bodies[body].mass
		for axis := 0; axis < 3; axis += 1 { ctx.cells[cell_index].center[axis] = ctx.bodies[body].position[axis] }
		return
	}
	var weighted: [3]f64
	ctx.cells[cell_index].mass = 0
	for child := 0; child < 8; child += 1 {
		child_index := ctx.cells[cell_index].child[child]
		if child_index < 0 do continue
		aggregate(ctx, child_index)
		ctx.cells[cell_index].mass += ctx.cells[child_index].mass
		for axis := 0; axis < 3; axis += 1 { weighted[axis] += ctx.cells[child_index].mass * ctx.cells[child_index].center[axis] }
	}
	for axis := 0; axis < 3; axis += 1 { ctx.cells[cell_index].center[axis] = weighted[axis] / ctx.cells[cell_index].mass }
}

interact :: proc "contextless" (mass: f64, position, query: [^]f64, eps_sq: f64,
		potential: ^f64, acceleration: [^]f64) {
	var d: [3]f64
	r2 := eps_sq
	for axis := 0; axis < 3; axis += 1 { d[axis] = position[axis] - query[axis]; r2 += d[axis] * d[axis] }
	contribution := mass / math.sqrt_f64(r2)
	potential^ -= contribution
	scale := contribution / r2
	for axis := 0; axis < 3; axis += 1 { acceleration[axis] += d[axis] * scale }
}

walk :: proc "contextless" (ctx: ^Context, cell_index: int, side, theta_sq: f64,
		query: [^]f64, eps_sq: f64, potential: ^f64, acceleration: [^]f64) {
	cell := ctx.cells[cell_index]
	if cell.body >= 0 { body := ctx.bodies[cell.body]; interact(body.mass, &body.position[0], query, eps_sq, potential, acceleration); return }
	distance_sq: f64 = 0
	for axis := 0; axis < 3; axis += 1 { d := cell.center[axis] - query[axis]; distance_sq += d*d }
	if theta_sq * distance_sq < side * side {
		for child := 0; child < 8; child += 1 { if cell.child[child] >= 0 do walk(ctx, cell.child[child], side/2.0, theta_sq, query, eps_sq, potential, acceleration) }
	} else { interact(cell.mass, &cell.center[0], query, eps_sq, potential, acceleration) }
}

@(export)
olden_bh :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 6 do return -1
	rn, theta, softening := input[0], input[1], input[2]
	if !(rn >= MIN_BODIES && rn <= MAX_BODIES) || rn != f64(int(rn)) || !(theta >= 0 && theta <= 2) || !(softening >= 0 && softening <= 1) do return -1
	count := int(rn)
	if input_length != c.size_t(6 + 4*count) do return -1
	var query: [3]f64
	for axis := 0; axis < 3; axis += 1 { query[axis] = input[3+axis]; if !(query[axis] >= -32 && query[axis] <= 32) do return -1 }
	var ctx: Context
	var minima: [3]f64 = {32,32,32}
	var maxima: [3]f64 = {-32,-32,-32}
	for body := 0; body < count; body += 1 {
		for axis := 0; axis < 3; axis += 1 {
			value := input[6+4*body+axis]
			if !(value >= -32 && value <= 32) || value != f64(int(value)) do return -1
			ctx.bodies[body].position[axis] = value
			minima[axis] = min(minima[axis], value); maxima[axis] = max(maxima[axis], value)
		}
		mass := input[9+4*body]
		if !(mass >= 1 && mass <= 16) do return -1
		ctx.bodies[body].mass = mass
	}
	for a := 0; a < count; a += 1 { for b := a+1; b < count; b += 1 { if ctx.bodies[a].position == ctx.bodies[b].position do return -1 } }
	inside := true
	for axis := 0; axis < 3; axis += 1 { if query[axis] < minima[axis] || query[axis] > maxima[axis] do inside = false }
	if inside do return -1
	if output == nil || output_capacity < 4 do return -2
	side := max(maxima[0]-minima[0], max(maxima[1]-minima[1], maxima[2]-minima[2]))
	if side <= 0 do return -1
	var center: [3]f64
	for axis := 0; axis < 3; axis += 1 { center[axis] = (minima[axis]+maxima[axis])/2 }
	root := new_cell(&ctx)
	for body := 0; body < count; body += 1 { if !insert_body(&ctx, root, body, &center[0], side/2, 0) do return -1 }
	aggregate(&ctx, root)
	var potential: f64
	var acceleration: [3]f64
	walk(&ctx, root, side, theta*theta, &query[0], softening*softening, &potential, &acceleration[0])
	output[0], output[1], output[2], output[3] = potential, acceleration[0], acceleration[1], acceleration[2]
	return 4
}
