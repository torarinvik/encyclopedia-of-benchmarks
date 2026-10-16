module gravitational_force
import math

@[export: 'gravitational_force']
pub fn gravitational_force(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 6 { return -1 }
		for i in 0 .. 6 { if values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100 { return -1 } }
		m1,x1,y1,m2,x2,y2 := values[0],values[1],values[2],values[3],values[4],values[5]
		if m1 > 1.0e12 || m1 < -1.0e12 || m2 > 1.0e12 || m2 < -1.0e12 ||
			(m1 != 0.0 && math.abs(m1) < 1.0e-12) || (m2 != 0.0 && math.abs(m2) < 1.0e-12) ||
			math.abs(x1)>1.0e6 || math.abs(y1)>1.0e6 || math.abs(x2)>1.0e6 || math.abs(y2)>1.0e6 { return -1 }
		dx,dy := x1-x2,y1-y2
		d2 := dx*dx+dy*dy
		if d2 != 0.0 && d2 < 1.0e-12 { return -1 }
		if isnil(output) || capacity < 2 { return -2 }
		if d2 == 0.0 { output[0]=0.0; output[1]=0.0; return 2 }
		distance := math.sqrt(d2)
		magnitude := 6.67430e-11*m1*m2/d2
		output[0]=magnitude*(dx/distance); output[1]=magnitude*(dy/distance)
		return 2
	}
}
