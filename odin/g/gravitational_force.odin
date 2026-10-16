package gravitational_force
import "core:c"
import "core:math"

@(export)
gravitational_force :: proc "c" (v: [^]f64, n: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if v == nil || n != c.size_t(6) do return -1
	for i := 0; i < 6; i += 1 { if v[i] != v[i] || v[i] > 1.0e100 || v[i] < -1.0e100 do return -1 }
	m1,x1,y1,m2,x2,y2 := v[0],v[1],v[2],v[3],v[4],v[5]
	if m1 > 1.0e12 || m1 < -1.0e12 || m2 > 1.0e12 || m2 < -1.0e12 ||
		(m1 != 0.0 && math.abs(m1) < 1.0e-12) || (m2 != 0.0 && math.abs(m2) < 1.0e-12) ||
		math.abs(x1)>1.0e6 || math.abs(y1)>1.0e6 || math.abs(x2)>1.0e6 || math.abs(y2)>1.0e6 do return -1
	dx,dy := x1-x2,y1-y2
	d2 := dx*dx+dy*dy
	if d2 != 0.0 && d2 < 1.0e-12 do return -1
	if output == nil || capacity < c.size_t(2) do return -2
	if d2 == 0.0 { output[0]=0.0; output[1]=0.0; return 2 }
	distance := math.sqrt(d2)
	magnitude := 6.67430e-11*m1*m2/d2
	output[0]=magnitude*(dx/distance); output[1]=magnitude*(dy/distance)
	return 2
}
