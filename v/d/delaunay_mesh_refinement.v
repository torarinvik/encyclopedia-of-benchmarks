module delaunay_mesh_refinement

import math

const input_length = 7
const max_output_bytes = 152
const coordinate_scale = i64(1000000)

fn orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
}

fn round_ratio_away(numerator i64, denominator i64) i64 {
	magnitude := if numerator < 0 { -numerator } else { numerator }
	rounded := (magnitude + denominator/2) / denominator
	return if numerator < 0 { -rounded } else { rounded }
}

fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset+byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'delaunay_mesh_refinement']
pub fn delaunay_mesh_refinement(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length != input_length || values[0] != 3 { return -1 }
		mut x := [3]i64{}
		mut y := [3]i64{}
		for i in 0 .. 3 {
			x[i], y[i] = values[1+2*i], values[2+2*i]
			if x[i] < -100 || x[i] > 100 || y[i] < -100 || y[i] > 100 { return -1 }
			for j in 0 .. i { if x[i] == x[j] && y[i] == y[j] { return -1 } }
		}
		area2 := orient(x[0],y[0],x[1],y[1],x[2],y[2])
		if area2 <= 0 { return -1 }
		for i in 0 .. 3 {
			j, k := (i+1)%3, (i+2)%3
			ux, uy := x[j]-x[i], y[j]-y[i]
			vx, vy := x[k]-x[i], y[k]-y[i]
			if ux*vx+uy*vy <= 0 { return -1 }
		}
		len01 := math.sqrt(f64((x[1]-x[0])*(x[1]-x[0])+(y[1]-y[0])*(y[1]-y[0])))
		len12 := math.sqrt(f64((x[2]-x[1])*(x[2]-x[1])+(y[2]-y[1])*(y[2]-y[1])))
		len20 := math.sqrt(f64((x[0]-x[2])*(x[0]-x[2])+(y[0]-y[2])*(y[0]-y[2])))
		shortest := if len01 < len12 { if len01 < len20 { len01 } else { len20 } } else { if len12 < len20 { len12 } else { len20 } }
		ratio := len01*len12*len20/(2.0*f64(area2)*shortest)
		beta := 1.0/(2.0*math.sin(3.14159265358979323846/9.0))
		refine := ratio > beta*(1.0+1e-12)
		mut staged := [max_output_bytes]u8{}
		put_i64(mut &staged[0],0,if refine { i64(4) } else { i64(3) })
		for i in 0 .. 3 {
			put_i64(mut &staged[0],8+16*i,x[i]*coordinate_scale)
			put_i64(mut &staged[0],16+16*i,y[i]*coordinate_scale)
		}
		if refine {
			ax, ay := x[0], y[0]
			bax, bay := x[1]-ax, y[1]-ay
			cax, cay := x[2]-ax, y[2]-ay
			denominator := 2*(bax*cay-bay*cax)
			balen_sq, calen_sq := bax*bax+bay*bay, cax*cax+cay*cay
			center_x_num := ax*denominator+cay*balen_sq-bay*calen_sq
			center_y_num := ay*denominator+bax*calen_sq-cax*balen_sq
			put_i64(mut &staged[0],56,round_ratio_away(center_x_num*coordinate_scale,denominator))
			put_i64(mut &staged[0],64,round_ratio_away(center_y_num*coordinate_scale,denominator))
			words := [10]i64{3,0,1,3,1,2,3,2,0,3}
			for i in 0 .. 10 { put_i64(mut &staged[0],72+8*i,words[i]) }
		} else {
			words := [4]i64{1,0,1,2}
			for i in 0 .. 4 { put_i64(mut &staged[0],56+8*i,words[i]) }
		}
		required := if refine { max_output_bytes } else { 88 }
		if output == nil || capacity < usize(required) { return -2 }
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
