// Exact incremental 3D convex hull volume for general-position points.
const point_capacity = 6
const face_capacity = 64
const edge_capacity = 3 * face_capacity

@[export: 'incremental_convex_hull_3d']
pub fn incremental_convex_hull_3d(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 20 { return -1 }
		if input[0] < 4 || input[0] > point_capacity { return -1 }
		n := int(input[0])
		if int(length) != 1 + 3*n { return -1 }
		mut points := [18]i64{}
		for i in 0 .. 3*n {
			if input[i+1] < -10 || input[i+1] > 10 { return -1 }
			points[i] = input[i+1]
		}
		for i in 0 .. n { for j in i+1 .. n {
			if points[3*i] == points[3*j] && points[3*i+1] == points[3*j+1] && points[3*i+2] == points[3*j+2] { return -1 }
		}}
		for i in 0 .. n { for j in i+1 .. n { for k in j+1 .. n { for ell in k+1 .. n {
			if side_of_face(points, i, j, k, ell) == 0 { return -1 }
		}}}}

		mut center_sum := [3]i64{}
		for i in 0 .. 4 { for axis in 0 .. 3 { center_sum[axis] += points[3*i+axis] }}
		mut face_a := [64]int{}
		mut face_b := [64]int{}
		mut face_c := [64]int{}
		face_a[0] = 0; face_a[1] = 0; face_a[2] = 0; face_a[3] = 1
		face_b[0] = 1; face_b[1] = 3; face_b[2] = 2; face_b[3] = 3
		face_c[0] = 2; face_c[1] = 1; face_c[2] = 3; face_c[3] = 2
		mut face_count := 4
		for f in 0 .. face_count {
			if center_side(points, face_a[f], face_b[f], face_c[f], center_sum) > 0 { face_b[f], face_c[f] = face_c[f], face_b[f] }
		}

		for point in 4 .. n {
			mut visible := [64]bool{}
			mut visible_count := 0
			for f in 0 .. face_count {
				visible[f] = side_of_face(points, face_a[f], face_b[f], face_c[f], point) > 0
				if visible[f] { visible_count += 1 }
			}
			if visible_count == 0 { continue }
			mut edge_a := [192]int{}
			mut edge_b := [192]int{}
			mut edge_count := 0
			for f in 0 .. face_count { if visible[f] {
				edge_a[edge_count] = face_a[f]; edge_b[edge_count] = face_b[f]; edge_count += 1
				edge_a[edge_count] = face_b[f]; edge_b[edge_count] = face_c[f]; edge_count += 1
				edge_a[edge_count] = face_c[f]; edge_b[edge_count] = face_a[f]; edge_count += 1
			}}
			mut next_a := [64]int{}
			mut next_b := [64]int{}
			mut next_c := [64]int{}
			mut next_count := 0
			for f in 0 .. face_count { if !visible[f] {
				next_a[next_count] = face_a[f]; next_b[next_count] = face_b[f]; next_c[next_count] = face_c[f]; next_count += 1
			}}
			for edge in 0 .. edge_count {
				mut copies := 0
				for other in 0 .. edge_count {
					if (edge_a[edge] == edge_a[other] && edge_b[edge] == edge_b[other]) || (edge_a[edge] == edge_b[other] && edge_b[edge] == edge_a[other]) { copies += 1 }
				}
				if copies != 1 { continue }
				if next_count >= face_capacity { return -1 }
				a := edge_a[edge]; mut b := edge_b[edge]; mut c := point
				if center_side(points, a, b, c, center_sum) > 0 { b, c = c, b }
				next_a[next_count] = a; next_b[next_count] = b; next_c[next_count] = c; next_count += 1
			}
			for f in 0 .. next_count { face_a[f] = next_a[f]; face_b[f] = next_b[f]; face_c[f] = next_c[f] }
			face_count = next_count
		}
		mut volume_six := i64(0)
		for f in 0 .. face_count { volume_six += origin_determinant(points, face_a[f], face_b[f], face_c[f]) }
		return volume_six
	}
}

@[inline]
fn side_of_face(points [18]i64, a int, b int, c int, point int) i64 {
	abx := points[3*b] - points[3*a]; aby := points[3*b+1] - points[3*a+1]; abz := points[3*b+2] - points[3*a+2]
	acx := points[3*c] - points[3*a]; acy := points[3*c+1] - points[3*a+1]; acz := points[3*c+2] - points[3*a+2]
	apx := points[3*point] - points[3*a]; apy := points[3*point+1] - points[3*a+1]; apz := points[3*point+2] - points[3*a+2]
	return (aby*acz-abz*acy)*apx + (abz*acx-abx*acz)*apy + (abx*acy-aby*acx)*apz
}

@[inline]
fn center_side(points [18]i64, a int, b int, c int, center_sum [3]i64) i64 {
	abx := points[3*b] - points[3*a]; aby := points[3*b+1] - points[3*a+1]; abz := points[3*b+2] - points[3*a+2]
	acx := points[3*c] - points[3*a]; acy := points[3*c+1] - points[3*a+1]; acz := points[3*c+2] - points[3*a+2]
	dx := center_sum[0] - 4*points[3*a]; dy := center_sum[1] - 4*points[3*a+1]; dz := center_sum[2] - 4*points[3*a+2]
	return (aby*acz-abz*acy)*dx + (abz*acx-abx*acz)*dy + (abx*acy-aby*acx)*dz
}

@[inline]
fn origin_determinant(points [18]i64, a int, b int, c int) i64 {
	ax := points[3*a]; ay := points[3*a+1]; az := points[3*a+2]
	bx := points[3*b]; by := points[3*b+1]; bz := points[3*b+2]
	cx := points[3*c]; cy := points[3*c+1]; cz := points[3*c+2]
	return ax*(by*cz-bz*cy) + ay*(bz*cx-bx*cz) + az*(bx*cy-by*cx)
}
