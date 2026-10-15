module rectangle_union_area

// Area covered by the union of two axis-aligned rectangles.
@[export: 'rectangle_union_area']
pub fn rectangle_union_area(coordinates &i64, length usize) i64 {
	if length != 8 { return -1 }
	for index in 0 .. 8 {
		value := unsafe { coordinates[index] }
		if value < i64(-1_000_000_000) || value > i64(1_000_000_000) { return -1 }
	}
	ax1 := unsafe { coordinates[0] }
	ay1 := unsafe { coordinates[1] }
	ax2 := unsafe { coordinates[2] }
	ay2 := unsafe { coordinates[3] }
	bx1 := unsafe { coordinates[4] }
	by1 := unsafe { coordinates[5] }
	bx2 := unsafe { coordinates[6] }
	by2 := unsafe { coordinates[7] }
	if ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2 { return -1 }
	area_a := (ax2 - ax1) * (ay2 - ay1)
	area_b := (bx2 - bx1) * (by2 - by1)
	mut overlap_left := ax1
	if bx1 > overlap_left { overlap_left = bx1 }
	mut overlap_right := ax2
	if bx2 < overlap_right { overlap_right = bx2 }
	mut overlap_bottom := ay1
	if by1 > overlap_bottom { overlap_bottom = by1 }
	mut overlap_top := ay2
	if by2 < overlap_top { overlap_top = by2 }
	overlap_width := overlap_right - overlap_left
	overlap_height := overlap_top - overlap_bottom
	mut overlap := i64(0)
	if overlap_width > 0 && overlap_height > 0 {
		overlap = overlap_width * overlap_height
	}
	return area_a + area_b - overlap
}
