module points_are_collinear_3d

// Check whether three bounded integer points lie on one 3D line.
@[export: 'points_are_collinear_3d']
pub fn points_are_collinear_3d(values &i64, length usize) i64 {
	if length != 9 { return -1 }
	for index in 0 .. 9 {
		value := unsafe { values[index] }
		if value < -10000 || value > 10000 { return -1 }
	}

	abx := unsafe { values[3] - values[0] }
	aby := unsafe { values[4] - values[1] }
	abz := unsafe { values[5] - values[2] }
	acx := unsafe { values[6] - values[0] }
	acy := unsafe { values[7] - values[1] }
	acz := unsafe { values[8] - values[2] }
	cross_x := aby * acz - abz * acy
	cross_y := abz * acx - abx * acz
	cross_z := abx * acy - aby * acx
	if cross_x == 0 && cross_y == 0 && cross_z == 0 { return 1 }
	return 0
}
