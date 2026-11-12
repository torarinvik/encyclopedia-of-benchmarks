package splash2_radiosity_refine

import "core:c"
import "core:math"

MAX_DEPTH :: 5

factor :: proc(tx, ty, source_area, sx, sy, gap: f64) -> f64 {
	distance_squared := (sx-tx)*(sx-tx) + (sy-ty)*(sy-ty) + gap*gap
	return source_area * gap * gap / (distance_squared * distance_squared)
}

visit :: proc(tx, ty, target_side, sx, sy, source_side, gap, bound: f64,
	allowed_depth, depth: int, weight: f64, transfer: ^f64, leaves, deepest: ^int) {
	coarse := factor(tx, ty, source_side*source_side, sx, sy, gap)
	split_source := source_side >= target_side
	parent_side := target_side
	if split_source { parent_side = source_side }
	child_side := parent_side * 0.5
	offset := parent_side * 0.25
	fine: f64 = 0
	for quadrant in 0..<4 {
		dx := offset
		dy := offset
		if (quadrant & 1) == 0 { dx = -offset }
		if (quadrant & 2) == 0 { dy = -offset }
		if split_source {
			fine += factor(tx, ty, child_side*child_side, sx+dx, sy+dy, gap)
		} else {
			fine += 0.25 * factor(tx+dx, ty+dy, source_side*source_side, sx, sy, gap)
		}
	}
	error := fine - coarse
	if error < 0 { error = -error }
	if depth >= allowed_depth || error <= bound {
		transfer^ += weight * coarse
		leaves^ += 1
		if depth > deepest^ { deepest^ = depth }
		return
	}
	for quadrant in 0..<4 {
		dx := offset
		dy := offset
		if (quadrant & 1) == 0 { dx = -offset }
		if (quadrant & 2) == 0 { dy = -offset }
		if split_source {
			visit(tx, ty, target_side, sx+dx, sy+dy, child_side, gap, bound,
				allowed_depth, depth+1, weight, transfer, leaves, deepest)
		} else {
			visit(tx+dx, ty+dy, child_side, sx, sy, source_side, gap, bound,
				allowed_depth, depth+1, weight*0.25, transfer, leaves, deepest)
		}
	}
}

@(export)
splash2_radiosity_refine :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 11 do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	tx, ty, ts := input[0], input[1], input[2]
	sx, sy, ss := input[3], input[4], input[5]
	gap, brightness, reflectance, bound, depth_value := input[6], input[7], input[8], input[9], input[10]
	if tx < -8 || tx > 8 || ty < -8 || ty > 8 || sx < -8 || sx > 8 || sy < -8 || sy > 8
		|| (ts != 1 && ts != 2 && ts != 4) || (ss != 1 && ss != 2 && ss != 4)
		|| gap < 1 || gap > 8 || ts > gap || ss > gap || brightness < 0 || brightness > 4
		|| reflectance < 0 || reflectance > 1 || bound < 0 || bound > 1
		|| depth_value < 0 || depth_value > MAX_DEPTH || f64(int(depth_value)) != depth_value do return -1
	if output == nil || output_capacity < 3 do return -2
	transfer: f64 = 0
	leaves, deepest := 0, 0
	visit(tx, ty, ts, sx, sy, ss, gap, bound, int(depth_value), 0, 1, &transfer, &leaves, &deepest)
	output[0] = reflectance * brightness * transfer
	output[1] = f64(leaves)
	output[2] = f64(deepest)
	return 3
}
