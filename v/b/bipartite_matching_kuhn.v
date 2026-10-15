module bipartite_matching_kuhn

const max_side = 64
const max_edges = max_side * max_side

fn try_augment(left int, right_count int, adjacency &bool, mut seen_right &bool, mut pair_right &i32) bool {
	for right in 0 .. right_count {
		if unsafe { !adjacency[left * max_side + right] || seen_right[right] } { continue }
		unsafe { seen_right[right] = true }
		mate := unsafe { pair_right[right] }
		if mate < 0 || try_augment(int(mate), right_count, adjacency, mut seen_right, mut pair_right) {
			unsafe { pair_right[right] = i32(left) }
			return true
		}
	}
	return false
}

// Return maximum matching cardinality, or -1 for malformed graph input.
@[export: 'bipartite_matching_kuhn']
pub fn bipartite_matching_kuhn(input &i64, length usize) i64 {
	if length < 3 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_side) || input[1] < 0 || input[1] > i64(max_side) || input[2] < 0 || input[2] > i64(max_edges) { return -1 }
		left_count := int(input[0])
		right_count := int(input[1])
		edge_count := int(input[2])
		if int(length) != 3 + 2 * edge_count { return -1 }
		mut adjacency := [max_side * max_side]bool{}
		for edge in 0 .. edge_count {
			left := input[3 + 2 * edge]
			right := input[4 + 2 * edge]
			if left < 0 || left >= i64(left_count) || right < 0 || right >= i64(right_count) { return -1 }
			adjacency[int(left) * max_side + int(right)] = true
		}
		mut pair_right := [max_side]i32{}
		for right in 0 .. right_count { pair_right[right] = -1 }
		mut matching := i64(0)
		for left in 0 .. left_count {
			mut seen_right := [max_side]bool{}
			if try_augment(left, right_count, &adjacency[0], mut seen_right[0], mut pair_right[0]) { matching++ }
		}
		return matching
	}
}
