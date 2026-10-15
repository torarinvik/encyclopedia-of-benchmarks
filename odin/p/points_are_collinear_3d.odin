package points_are_collinear_3d

import "core:c"

// Check whether three bounded integer points lie on one 3D line.
@(export)
points_are_collinear_3d :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length != 9 do return -1
	for index := 0; index < 9; index += 1 {
		value := values[index]
		if value < -10000 || value > 10000 do return -1
	}

	abx := values[3] - values[0]
	aby := values[4] - values[1]
	abz := values[5] - values[2]
	acx := values[6] - values[0]
	acy := values[7] - values[1]
	acz := values[8] - values[2]
	cross_x := aby * acz - abz * acy
	cross_y := abz * acx - abx * acz
	cross_z := abx * acy - aby * acx
	if cross_x == 0 && cross_y == 0 && cross_z == 0 do return 1
	return 0
}
