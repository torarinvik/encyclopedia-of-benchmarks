package rectangle_union_area

import "core:c"

COORDINATE_LIMIT :: i64(1_000_000_000)

// Area covered by the union of two axis-aligned rectangles.
@(export)
rectangle_union_area :: proc "c" (coordinates: [^]i64, length: c.size_t) -> i64 {
	if length != 8 do return -1
	for index := 0; index < 8; index += 1 {
		if coordinates[index] < -COORDINATE_LIMIT || coordinates[index] > COORDINATE_LIMIT do return -1
	}
	ax1, ay1 := coordinates[0], coordinates[1]
	ax2, ay2 := coordinates[2], coordinates[3]
	bx1, by1 := coordinates[4], coordinates[5]
	bx2, by2 := coordinates[6], coordinates[7]
	if ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2 do return -1
	area_a := (ax2 - ax1) * (ay2 - ay1)
	area_b := (bx2 - bx1) * (by2 - by1)
	overlap_width := min(ax2, bx2) - max(ax1, bx1)
	overlap_height := min(ay2, by2) - max(ay1, by1)
	overlap := i64(0)
	if overlap_width > 0 && overlap_height > 0 {
		overlap = overlap_width * overlap_height
	}
	return area_a + area_b - overlap
}
