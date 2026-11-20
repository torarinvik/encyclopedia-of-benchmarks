// Exact incremental 3D convex hull volume for general-position points.
package incremental_convex_hull_3d

import "core:c"

POINT_CAPACITY :: 6
FACE_CAPACITY :: 64
EDGE_CAPACITY :: 3 * FACE_CAPACITY

side_of_face :: proc "contextless" (points: [^]i64, a, b, c, point: int) -> i64 {
	abx := points[3*b] - points[3*a]; aby := points[3*b+1] - points[3*a+1]; abz := points[3*b+2] - points[3*a+2]
	acx := points[3*c] - points[3*a]; acy := points[3*c+1] - points[3*a+1]; acz := points[3*c+2] - points[3*a+2]
	apx := points[3*point] - points[3*a]; apy := points[3*point+1] - points[3*a+1]; apz := points[3*point+2] - points[3*a+2]
	return (aby*acz-abz*acy)*apx + (abz*acx-abx*acz)*apy + (abx*acy-aby*acx)*apz
}

center_side :: proc "contextless" (points: [^]i64, a, b, c: int, center_sum: [3]i64) -> i64 {
	abx := points[3*b] - points[3*a]; aby := points[3*b+1] - points[3*a+1]; abz := points[3*b+2] - points[3*a+2]
	acx := points[3*c] - points[3*a]; acy := points[3*c+1] - points[3*a+1]; acz := points[3*c+2] - points[3*a+2]
	dx := center_sum[0] - 4*points[3*a]; dy := center_sum[1] - 4*points[3*a+1]; dz := center_sum[2] - 4*points[3*a+2]
	return (aby*acz-abz*acy)*dx + (abz*acx-abx*acz)*dy + (abx*acy-aby*acx)*dz
}

origin_determinant :: proc "contextless" (points: [^]i64, a, b, c: int) -> i64 {
	ax := points[3*a]; ay := points[3*a+1]; az := points[3*a+2]
	bx := points[3*b]; by := points[3*b+1]; bz := points[3*b+2]
	cx := points[3*c]; cy := points[3*c+1]; cz := points[3*c+2]
	return ax*(by*cz-bz*cy) + ay*(bz*cx-bx*cz) + az*(bx*cy-by*cx)
}

@(export)
incremental_convex_hull_3d :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 20 do return -1
	if input[0] < 4 || input[0] > POINT_CAPACITY do return -1
	n := int(input[0])
	if int(length) != 1 + 3*n do return -1
	points: [18]i64 = {}
	for i := 0; i < 3*n; i += 1 {
		if input[i+1] < -10 || input[i+1] > 10 do return -1
		points[i] = input[i+1]
	}
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 {
		if points[3*i] == points[3*j] && points[3*i+1] == points[3*j+1] && points[3*i+2] == points[3*j+2] do return -1
	}}
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { for k := j+1; k < n; k += 1 { for ell := k+1; ell < n; ell += 1 {
		if side_of_face(&points[0], i, j, k, ell) == 0 do return -1
	}}}}

	center_sum: [3]i64 = {}
	for i := 0; i < 4; i += 1 { for axis := 0; axis < 3; axis += 1 { center_sum[axis] += points[3*i+axis] }}
	face_a: [64]int = {}; face_b: [64]int = {}; face_c: [64]int = {}
	face_a[0] = 0; face_a[1] = 0; face_a[2] = 0; face_a[3] = 1
	face_b[0] = 1; face_b[1] = 3; face_b[2] = 2; face_b[3] = 3
	face_c[0] = 2; face_c[1] = 1; face_c[2] = 3; face_c[3] = 2
	face_count := 4
	for f := 0; f < face_count; f += 1 {
		if center_side(&points[0], face_a[f], face_b[f], face_c[f], center_sum) > 0 { face_b[f], face_c[f] = face_c[f], face_b[f] }
	}

	for point := 4; point < n; point += 1 {
		visible: [64]bool = {}
		visible_count := 0
		for f := 0; f < face_count; f += 1 {
			visible[f] = side_of_face(&points[0], face_a[f], face_b[f], face_c[f], point) > 0
			if visible[f] { visible_count += 1 }
		}
		if visible_count == 0 do continue
		edge_a: [192]int; edge_b: [192]int; edge_count := 0
		for f := 0; f < face_count; f += 1 { if visible[f] {
			edge_a[edge_count] = face_a[f]; edge_b[edge_count] = face_b[f]; edge_count += 1
			edge_a[edge_count] = face_b[f]; edge_b[edge_count] = face_c[f]; edge_count += 1
			edge_a[edge_count] = face_c[f]; edge_b[edge_count] = face_a[f]; edge_count += 1
		}}
		next_a: [64]int; next_b: [64]int; next_c: [64]int; next_count := 0
		for f := 0; f < face_count; f += 1 { if !visible[f] {
			next_a[next_count] = face_a[f]; next_b[next_count] = face_b[f]; next_c[next_count] = face_c[f]; next_count += 1
		}}
		for edge := 0; edge < edge_count; edge += 1 {
			copies := 0
			for other := 0; other < edge_count; other += 1 {
				if (edge_a[edge] == edge_a[other] && edge_b[edge] == edge_b[other]) || (edge_a[edge] == edge_b[other] && edge_b[edge] == edge_a[other]) { copies += 1 }
			}
			if copies != 1 { continue }
			if next_count >= FACE_CAPACITY do return -1
			a := edge_a[edge]; b := edge_b[edge]; c := point
			if center_side(&points[0], a, b, c, center_sum) > 0 { b, c = c, b }
			next_a[next_count] = a; next_b[next_count] = b; next_c[next_count] = c; next_count += 1
		}
		for f := 0; f < next_count; f += 1 { face_a[f] = next_a[f]; face_b[f] = next_b[f]; face_c[f] = next_c[f] }
		face_count = next_count
	}
	volume_six: i64 = 0
	for f := 0; f < face_count; f += 1 { volume_six += origin_determinant(&points[0], face_a[f], face_b[f], face_c[f]) }
	return volume_six
}
