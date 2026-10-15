module bipartite_matching_hopcroft_karp

const max_side = 64
const max_edges = max_side * max_side
const inf_distance = 1_000_000

fn dfs_augment(left int, right_count int, adjacency &bool, mut distance &i32,
		nil_distance i32, mut pair_left &i32, mut pair_right &i32) bool {
	for right in 0 .. right_count {
		if unsafe { !adjacency[left * max_side + right] } { continue }
		mate := unsafe { pair_right[right] }
		if mate < 0 {
			if unsafe { distance[left] + 1 } != nil_distance { continue }
			unsafe {
				pair_left[left] = i32(right)
				pair_right[right] = i32(left)
			}
			return true
		}
		if unsafe { distance[int(mate)] == distance[left] + 1 } &&
			dfs_augment(int(mate), right_count, adjacency, mut distance, nil_distance, mut pair_left, mut pair_right) {
			unsafe {
				pair_left[left] = i32(right)
				pair_right[right] = i32(left)
			}
			return true
		}
	}
	unsafe { distance[left] = inf_distance }
	return false
}

fn bfs_layers(left_count int, right_count int, adjacency &bool, pair_right &i32, mut distance &i32) i32 {
	mut queue := [64]int{}
	mut head := 0
	mut tail := 0
	for left in 0 .. left_count {
		if unsafe { distance[left] == 0 } {
			queue[tail] = left
			tail++
		}
	}
	mut nil_distance := i32(inf_distance)
	for head < tail {
		left := queue[head]
		head++
		if unsafe { distance[left] + 1 > nil_distance } { continue }
		for right in 0 .. right_count {
			if unsafe { !adjacency[left * max_side + right] } { continue }
			mate := unsafe { pair_right[right] }
			if mate < 0 {
				if unsafe { distance[left] + 1 } < nil_distance { nil_distance = unsafe { distance[left] + 1 } }
			} else if unsafe { distance[int(mate)] < 0 } {
				unsafe { distance[int(mate)] = distance[left] + 1 }
				queue[tail] = int(mate)
				tail++
			}
		}
	}
	return nil_distance
}

// Return maximum matching cardinality, or -1 for malformed graph input.
@[export: 'bipartite_matching_hopcroft_karp']
pub fn bipartite_matching_hopcroft_karp(input &i64, length usize) i64 {
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
		mut pair_left := [max_side]i32{}
		mut pair_right := [max_side]i32{}
		mut distance := [max_side]i32{}
		for left in 0 .. left_count { pair_left[left] = -1 }
		for right in 0 .. right_count { pair_right[right] = -1 }
		mut matching := i64(0)
		for {
			for left in 0 .. left_count { distance[left] = if pair_left[left] < 0 { 0 } else { -1 } }
			nil_distance := bfs_layers(left_count, right_count, &adjacency[0], &pair_right[0], &distance[0])
			if nil_distance == inf_distance { break }
			for left in 0 .. left_count {
				if pair_left[left] < 0 && dfs_augment(left, right_count, &adjacency[0], mut distance,
					nil_distance, mut pair_left[0], mut pair_right[0]) { matching++ }
			}
		}
		return matching
	}
}
