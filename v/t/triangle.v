module triangle

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := u64(math.bits_from_f64(value))
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'triangle']
pub fn triangle(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 6 { return -1 }
	unsafe {
		for i in 0 .. 6 { if input[i] < -100 || input[i] > 100 { return -1 } }
		x1,y1,x2,y2,x3,y3 := f64(input[0]),f64(input[1]),f64(input[2]),f64(input[3]),f64(input[4]),f64(input[5])
		if x1==x2 || x1==x3 || x2==x3 || y3==y1 || y3==y2 { return -1 }
		determinant := x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
		if determinant==0 { return -1 }
		s1,s2,s3 := x1*x1+y1*y1,x2*x2+y2*y2,x3*x3+y3*y3
		circum_x := (s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2*determinant)
		circum_y := -(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2*determinant)
		side_a := math.sqrt((x2-x3)*(x2-x3)+(y2-y3)*(y2-y3))
		side_b := math.sqrt((x1-x3)*(x1-x3)+(y1-y3)*(y1-y3))
		side_c := math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
		perimeter := side_a+side_b+side_c
		incenter_x := (side_a*x1+side_b*x2+side_c*x3)/perimeter
		incenter_y := (side_a*y1+side_b*y2+side_c*y3)/perimeter
		inv_m1,inv_m2 := -(x3-x1)/(y3-y1),-(x3-x2)/(y3-y2)
		rhs1,rhs2 := inv_m2*x1-y1,inv_m1*x2-y2
		solve_det := inv_m1-inv_m2
		if solve_det==0 { return -1 }
		ortho_x,ortho_y := (-rhs1+rhs2)/solve_det,(inv_m2*rhs2-inv_m1*rhs1)/solve_det
		if capacity < 48 || unsafe { output == nil } { return -2 }
		values := [6]f64{circum_x,circum_y,incenter_x,incenter_y,ortho_x,ortho_y}
		for i in 0 .. 6 { put_f64_le(mut output,i*8,values[i]) }
		return 48
	}
}
