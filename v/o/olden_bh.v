module olden_bh

import math

const min_bodies = 2
const max_bodies = 16
const max_nodes = 1024
const max_depth = 16

struct BhBody {
	mut:
	position [3]f64
	mass f64
}

struct BhCell {
	mut:
	body int
	child [8]int
	mass f64
	center [3]f64
}

struct BhContext {
	mut:
	bodies [max_bodies]BhBody
	cells [max_nodes]BhCell
	used int
}

fn octant(position [3]f64, center [3]f64) int {
	mut result := 0
	if position[0] >= center[0] { result |= 1 }
	if position[1] >= center[1] { result |= 2 }
	if position[2] >= center[2] { result |= 4 }
	return result
}

fn new_cell(mut ctx &BhContext) int {
	if ctx.used >= max_nodes { return -1 }
	id := ctx.used
	ctx.used++
	ctx.cells[id].body = -1
	for child in 0 .. 8 { ctx.cells[id].child[child] = -1 }
	return id
}

fn insert_body(mut ctx &BhContext, cell_index int, body_index int, center [3]f64,
	half f64, depth int) bool {
	old_body := ctx.cells[cell_index].body
	if old_body == -1 { ctx.cells[cell_index].body = body_index; return true }
	if depth >= max_depth { return false }
	if old_body >= 0 { ctx.cells[cell_index].body = -2 }
	item_count := if old_body >= 0 { 2 } else { 1 }
	for item_index in 0 .. item_count {
		which_body := if old_body >= 0 && item_index == 0 { old_body } else { body_index }
		child := octant(ctx.bodies[which_body].position, center)
		if ctx.cells[cell_index].child[child] < 0 {
			created := new_cell(mut ctx)
			if created < 0 { return false }
			ctx.cells[cell_index].child[child] = created
		}
		mut next_center := [3]f64{}
		for axis in 0 .. 3 {
			direction := if child & (1 << axis) != 0 { half / 2.0 } else { -half / 2.0 }
			next_center[axis] = center[axis] + direction
		}
		if !insert_body(mut ctx, ctx.cells[cell_index].child[child], which_body, next_center, half / 2.0, depth + 1) { return false }
	}
	return true
}

fn aggregate(mut ctx &BhContext, cell_index int) {
	body := ctx.cells[cell_index].body
	if body >= 0 {
		ctx.cells[cell_index].mass = ctx.bodies[body].mass
		for axis in 0 .. 3 { ctx.cells[cell_index].center[axis] = ctx.bodies[body].position[axis] }
		return
	}
	mut weighted := [3]f64{}
	ctx.cells[cell_index].mass = 0.0
	for child in 0 .. 8 {
		child_index := ctx.cells[cell_index].child[child]
		if child_index < 0 { continue }
		aggregate(mut ctx, child_index)
		ctx.cells[cell_index].mass += ctx.cells[child_index].mass
		for axis in 0 .. 3 { weighted[axis] += ctx.cells[child_index].mass * ctx.cells[child_index].center[axis] }
	}
	for axis in 0 .. 3 { ctx.cells[cell_index].center[axis] = weighted[axis] / ctx.cells[cell_index].mass }
}

fn interact(mass f64, position [3]f64, query [3]f64, eps_sq f64,
	mut potential f64, mut acceleration [3]f64) {
	mut d := [3]f64{}
	mut r2 := eps_sq
	for axis in 0 .. 3 { d[axis] = position[axis] - query[axis]; r2 += d[axis] * d[axis] }
	contribution := mass / math.sqrt(r2)
	potential -= contribution
	scale := contribution / r2
	for axis in 0 .. 3 { acceleration[axis] += d[axis] * scale }
}

fn walk(ctx &BhContext, cell_index int, side f64, theta_sq f64, query [3]f64,
	eps_sq f64, mut potential f64, mut acceleration [3]f64) {
	cell := ctx.cells[cell_index]
	if cell.body >= 0 {
		body := ctx.bodies[cell.body]
		interact(body.mass, body.position, query, eps_sq, mut potential, mut acceleration)
		return
	}
	mut distance_sq := 0.0
	for axis in 0 .. 3 { d := cell.center[axis] - query[axis]; distance_sq += d*d }
	if theta_sq * distance_sq < side * side {
		for child in 0 .. 8 {
			if cell.child[child] >= 0 { walk(ctx, cell.child[child], side/2.0, theta_sq, query, eps_sq, mut potential, mut acceleration) }
		}
	} else { interact(cell.mass, cell.center, query, eps_sq, mut potential, mut acceleration) }
}

@[export: 'olden_bh']
pub fn olden_bh(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 6 { return -1 }
		rn, theta, softening := input[0], input[1], input[2]
		if !(rn >= f64(min_bodies) && rn <= f64(max_bodies)) || f64(int(rn)) != rn ||
			!(theta >= 0.0 && theta <= 2.0) || !(softening >= 0.0 && softening <= 1.0) { return -1 }
		count := int(rn)
		if input_length != usize(6 + 4*count) { return -1 }
		mut query := [3]f64{}
		for axis in 0 .. 3 { query[axis] = input[3+axis]; if !(query[axis] >= -32.0 && query[axis] <= 32.0) { return -1 } }
		mut ctx := BhContext{}
		mut minima := [3]f64{32.0,32.0,32.0}
		mut maxima := [3]f64{-32.0,-32.0,-32.0}
		for body in 0 .. count {
			for axis in 0 .. 3 {
				value := input[6+4*body+axis]
				if !(value >= -32.0 && value <= 32.0) || f64(int(value)) != value { return -1 }
				ctx.bodies[body].position[axis] = value
				if value < minima[axis] { minima[axis] = value }
				if value > maxima[axis] { maxima[axis] = value }
			}
			mass := input[9+4*body]
			if !(mass >= 1.0 && mass <= 16.0) { return -1 }
			ctx.bodies[body].mass = mass
		}
		for a in 0 .. count {
			for b in a+1 .. count {
				if ctx.bodies[a].position[0] == ctx.bodies[b].position[0] && ctx.bodies[a].position[1] == ctx.bodies[b].position[1] && ctx.bodies[a].position[2] == ctx.bodies[b].position[2] { return -1 }
			}
		}
		mut inside := true
		for axis in 0 .. 3 { if query[axis] < minima[axis] || query[axis] > maxima[axis] { inside = false } }
		if inside { return -1 }
		if isnil(output) || output_capacity < 4 { return -2 }
		mut side := maxima[0] - minima[0]
		if maxima[1] - minima[1] > side { side = maxima[1] - minima[1] }
		if maxima[2] - minima[2] > side { side = maxima[2] - minima[2] }
		if side <= 0.0 { return -1 }
		mut center := [3]f64{}
		for axis in 0 .. 3 { center[axis] = (minima[axis] + maxima[axis]) / 2.0 }
		root := new_cell(mut ctx)
		for body in 0 .. count { if !insert_body(mut ctx, root, body, center, side/2.0, 0) { return -1 } }
		aggregate(mut ctx, root)
		mut potential := 0.0
		mut acceleration := [3]f64{}
		walk(ctx, root, side, theta*theta, query, softening*softening, mut potential, mut acceleration)
		output[0] = potential; output[1] = acceleration[0]; output[2] = acceleration[1]; output[3] = acceleration[2]
		return 4
	}
}
