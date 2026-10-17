module kcenters

@[export: 'kcenters']
pub fn kcenters(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 66 { return -1 }
	point_count := values[0]
	center_count := values[1]
	if point_count < 1 || point_count > 8 || center_count < 1 || center_count > point_count { return -1 }
	if length != usize(2 + point_count * point_count) { return -1 }
	unsafe {
		for row in 0 ..< int(point_count) {
			for column in 0 ..< int(point_count) {
				distance := values[2 + row * int(point_count) + column]
				if distance < 0 || distance > 1_000_000 || (row == column && distance != 0) { return -1 }
				if distance != values[2 + column * int(point_count) + row] { return -1 }
			}
		}
	}

	mut selected := [8]bool{}
	mut max_distance := [8]i64{}
	for point in 0 ..< int(point_count) { max_distance[point] = 2_147_483_647 }
	selected[0] = true
	unsafe {
		for point in 1 ..< int(point_count) {
			distance := values[2 + point]
			if distance < max_distance[point] { max_distance[point] = distance }
		}
	}
	for _ in 1 ..< int(center_count) {
		mut farthest := -1
		for point in 0 ..< int(point_count) {
			far := int(farthest)
			if !selected[point] && (farthest == -1 || max_distance[point] > max_distance[far]) { farthest = i64(point) }
		}
		center := int(farthest)
		selected[center] = true
		unsafe {
			for point in 0 ..< int(point_count) {
				distance := values[2 + center * int(point_count) + point]
				if distance < max_distance[point] { max_distance[point] = distance }
			}
		}
	}
	mut result := i64(0)
	for point in 0 ..< int(point_count) {
		if max_distance[point] > result { result = max_distance[point] }
	}
	return result
}
