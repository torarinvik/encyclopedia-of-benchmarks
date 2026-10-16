package problem86

MAX_LIMIT :: 1_000_000

is_square :: proc(value: i64) -> bool {
	root := value
	next := (root + 1) / 2
	for next < root { root = next; next = (root + value / root) / 2 }
	return root * root == value
}

@(export)
problem86 :: proc "c" (limit: i64) -> i64 {
	if limit > MAX_LIMIT do return -1
	if limit < 0 do return 0
	cuboid_count := i64(0)
	max_side := i64(0)
	for cuboid_count <= limit {
		max_side += 1
		for sum_sides := i64(2); sum_sides <= 2 * max_side; sum_sides += 1 {
			if !is_square(sum_sides * sum_sides + max_side * max_side) do continue
			high := min(max_side, sum_sides / 2)
			low := max(i64(1), sum_sides - max_side)
			cuboid_count += high - low + 1
		}
	}
	return max_side
}
