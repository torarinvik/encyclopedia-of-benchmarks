module problem86

const max_limit = 1000000

fn is_square(value i64) bool {
	mut root := value
	mut next := (root + 1) / 2
	for next < root {
		root = next
		next = (root + value / root) / 2
	}
	return root * root == value
}

@[export: 'problem86']
pub fn problem86(limit i64) i64 {
	if limit > max_limit { return -1 }
	if limit < 0 { return 0 }
	mut cuboid_count := i64(0)
	mut max_side := i64(0)
	for cuboid_count <= limit {
		max_side++
		for sum_sides := i64(2); sum_sides <= 2 * max_side; sum_sides++ {
			if !is_square(sum_sides * sum_sides + max_side * max_side) { continue }
			high := if max_side < sum_sides / 2 { max_side } else { sum_sides / 2 }
			low := if sum_sides - max_side > 1 { sum_sides - max_side } else { i64(1) }
			cuboid_count += high - low + 1
		}
	}
	return max_side
}
