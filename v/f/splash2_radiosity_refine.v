module splash2_radiosity_refine

import math

const max_depth = 5

fn factor(tx f64, ty f64, source_area f64, sx f64, sy f64, gap f64) f64 {
	distance_squared := (sx-tx)*(sx-tx) + (sy-ty)*(sy-ty) + gap*gap
	return source_area * gap * gap / (distance_squared * distance_squared)
}

fn visit(tx f64, ty f64, target_side f64, sx f64, sy f64, source_side f64,
	gap f64, bound f64, allowed_depth int, depth int, weight f64,
	mut transfer &f64, mut leaves &int, mut deepest &int) {
	coarse := factor(tx, ty, source_side*source_side, sx, sy, gap)
	split_source := source_side >= target_side
	parent_side := if split_source { source_side } else { target_side }
	child_side := parent_side * 0.5
	offset := parent_side * 0.25
	mut fine := 0.0
	for quadrant in 0 .. 4 {
		dx := if (quadrant & 1) != 0 { offset } else { -offset }
		dy := if (quadrant & 2) != 0 { offset } else { -offset }
		if split_source {
			fine += factor(tx, ty, child_side*child_side, sx+dx, sy+dy, gap)
		} else {
			fine += 0.25 * factor(tx+dx, ty+dy, source_side*source_side, sx, sy, gap)
		}
	}
	mut error := fine - coarse
	if error < 0 { error = -error }
	if depth >= allowed_depth || error <= bound {
		unsafe { transfer[0] += weight * coarse; leaves[0]++; if depth > deepest[0] { deepest[0] = depth } }
		return
	}
	for quadrant in 0 .. 4 {
		dx := if (quadrant & 1) != 0 { offset } else { -offset }
		dy := if (quadrant & 2) != 0 { offset } else { -offset }
		if split_source {
			visit(tx, ty, target_side, sx+dx, sy+dy, child_side, gap, bound,
				allowed_depth, depth+1, weight, mut transfer, mut leaves, mut deepest)
		} else {
			visit(tx+dx, ty+dy, child_side, sx, sy, source_side, gap, bound,
				allowed_depth, depth+1, weight*0.25, mut transfer, mut leaves, mut deepest)
		}
	}
}

@[export: 'splash2_radiosity_refine']
pub fn splash2_radiosity_refine(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 11 { return -1 }
		for i in 0 .. input_length { if !math.is_finite(input[i]) { return -1 } }
		tx, ty, ts := input[0], input[1], input[2]
		sx, sy, ss := input[3], input[4], input[5]
		gap, brightness, reflectance, bound, depth_value := input[6], input[7], input[8], input[9], input[10]
		if tx < -8 || tx > 8 || ty < -8 || ty > 8 || sx < -8 || sx > 8 || sy < -8 || sy > 8
			|| (ts != 1 && ts != 2 && ts != 4) || (ss != 1 && ss != 2 && ss != 4)
			|| gap < 1 || gap > 8 || ts > gap || ss > gap || brightness < 0 || brightness > 4
			|| reflectance < 0 || reflectance > 1 || bound < 0 || bound > 1
			|| depth_value < 0 || depth_value > max_depth || f64(int(depth_value)) != depth_value { return -1 }
		if output == nil || output_capacity < 3 { return -2 }
		mut transfer := 0.0
		mut leaves := 0
		mut deepest := 0
		visit(tx, ty, ts, sx, sy, ss, gap, bound, int(depth_value), 0, 1.0,
			mut transfer, mut leaves, mut deepest)
		output[0] = reflectance * brightness * transfer
		output[1] = f64(leaves)
		output[2] = f64(deepest)
		return 3
	}
}
