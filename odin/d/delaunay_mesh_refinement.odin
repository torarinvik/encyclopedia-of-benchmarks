package delaunay_mesh_refinement

import "core:c"
import "core:math"

INPUT_LENGTH :: 7
MAX_OUTPUT_BYTES :: 152
COORDINATE_SCALE :: i64(1_000_000)

orient :: proc "contextless" (ax, ay, bx, by, cx, cy: i64) -> i64 {
	return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
}

round_ratio_away :: proc "contextless" (numerator, denominator: i64) -> i64 {
	magnitude := numerator
	if magnitude < 0 { magnitude = -magnitude }
	rounded := (magnitude + denominator/2) / denominator
	if numerator < 0 { return -rounded }
	return rounded
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
delaunay_mesh_refinement :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != INPUT_LENGTH || values[0] != 3 { return -1 }
	x, y: [3]i64
	for i := 0; i < 3; i += 1 {
		x[i], y[i] = values[1+2*i], values[2+2*i]
		if x[i] < -100 || x[i] > 100 || y[i] < -100 || y[i] > 100 { return -1 }
		for j := 0; j < i; j += 1 { if x[i] == x[j] && y[i] == y[j] { return -1 } }
	}
	area2 := orient(x[0], y[0], x[1], y[1], x[2], y[2])
	if area2 <= 0 { return -1 }
	for i := 0; i < 3; i += 1 {
		j, k := (i+1)%3, (i+2)%3
		ux, uy := x[j]-x[i], y[j]-y[i]
		vx, vy := x[k]-x[i], y[k]-y[i]
		if ux*vx+uy*vy <= 0 { return -1 }
	}
	len01 := math.sqrt(f64((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0])))
	len12 := math.sqrt(f64((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1])))
	len20 := math.sqrt(f64((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2])))
	shortest := min(len01, min(len12, len20))
	ratio := len01*len12*len20 / (2.0*f64(area2)*shortest)
	beta := 1.0 / (2.0*math.sin(3.14159265358979323846/9.0))
	refine := ratio > beta*(1.0+1e-12)

	staged: [MAX_OUTPUT_BYTES]u8
	put_i64(&staged[0], 0, i64(3))
	if refine { put_i64(&staged[0], 0, i64(4)) }
	for i := 0; i < 3; i += 1 {
		put_i64(&staged[0], 8+16*i, x[i]*COORDINATE_SCALE)
		put_i64(&staged[0], 16+16*i, y[i]*COORDINATE_SCALE)
	}
	if refine {
		ax, ay := x[0], y[0]
		bax, bay := x[1]-ax, y[1]-ay
		cax, cay := x[2]-ax, y[2]-ay
		denominator := 2*(bax*cay-bay*cax)
		balen_sq, calen_sq := bax*bax+bay*bay, cax*cax+cay*cay
		center_x_num := ax*denominator+cay*balen_sq-bay*calen_sq
		center_y_num := ay*denominator+bax*calen_sq-cax*balen_sq
		put_i64(&staged[0], 56, round_ratio_away(center_x_num*COORDINATE_SCALE, denominator))
		put_i64(&staged[0], 64, round_ratio_away(center_y_num*COORDINATE_SCALE, denominator))
		words := [10]i64{3, 0, 1, 3, 1, 2, 3, 2, 0, 3}
		for i := 0; i < 10; i += 1 { put_i64(&staged[0], 72+8*i, words[i]) }
	} else {
		words := [4]i64{1, 0, 1, 2}
		for i := 0; i < 4; i += 1 { put_i64(&staged[0], 56+8*i, words[i]) }
	}
	required := c.size_t(88)
	if refine { required = MAX_OUTPUT_BYTES }
	if output == nil || capacity < required { return -2 }
	for i := c.size_t(0); i < required; i += 1 { output[i] = staged[i] }
	return i64(required)
}
