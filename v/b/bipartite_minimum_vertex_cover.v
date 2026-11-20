// Ordered augmenting-path matching and canonical minimum-cover certificate.
module bipartite_minimum_vertex_cover

const max_side = 8
const max_vertices = 16
const max_parseable_input = 11

fn augment_left(left int, left_count int, right_count int, rows &u16, states &i32,
	mut match_right &i32, mut seen &bool) bool {
	for right in 0 .. right_count {
		if unsafe { (rows[left] & (u16(1) << right)) == 0 || seen[right] || states[left_count + right] != -1 } { continue }
		unsafe { seen[right] = true }
		owner := unsafe { match_right[right] }
		if owner < 0 || augment_left(int(owner), left_count, right_count, rows, states,
			mut match_right, mut seen) {
			unsafe { match_right[right] = i32(left) }
			return true
		}
	}
	false
}

fn maximum_matching(left_count int, right_count int, rows &u16, states &i32,
	mut match_right &i32) int {
	unsafe { for right in 0 .. right_count { match_right[right] = -1 } }
	mut size := 0
	for left in 0 .. left_count {
		if unsafe { states[left] != -1 } { continue }
		mut seen := [max_side]bool{}
		if augment_left(left, left_count, right_count, rows, states,
			mut match_right, mut seen[0]) { size++ }
	}
	size
}

fn bit_count(value_input u32) int {
	mut value := value_input
	mut count := 0
	for value != 0 { count += int(value & 1); value >>= 1 }
	count
}

fn alternating_cover(left_count int, right_count int, rows &u16, match_right &i32) u32 {
	mut matched_left := [max_side]bool{}
	mut reached_left := [max_side]bool{}
	mut reached_right := [max_side]bool{}
	mut queue := [max_side]int{}
	mut head := 0
	mut tail := 0
	unsafe {
		for right in 0 .. right_count {
			if match_right[right] >= 0 { matched_left[int(match_right[right])] = true }
		}
	}
	for left in 0 .. left_count {
		if !matched_left[left] {
			reached_left[left] = true
			queue[tail] = left
			tail++
		}
	}
	for head < tail {
		left := queue[head]
		head++
		unsafe {
			for right in 0 .. right_count {
				if (rows[left] & (u16(1) << right)) == 0 || reached_right[right] || match_right[right] < 0 { continue }
				reached_right[right] = true
				owner := int(match_right[right])
				if !reached_left[owner] {
					reached_left[owner] = true
					queue[tail] = owner
					tail++
				}
			}
		}
	}
	mut result := u32(0)
	for left in 0 .. left_count { if !reached_left[left] { result |= u32(1) << left } }
	for right in 0 .. right_count { if reached_right[right] { result |= u32(1) << (left_count + right) } }
	result
}

fn minimum_completion_size(left_count int, right_count int, rows &u16, input_states &i32) int {
	mut states := [max_vertices]i32{}
	unsafe { for i in 0 .. left_count + right_count { states[i] = input_states[i] } }
	mut changed := true
	for changed {
		changed = false
		unsafe {
			for left in 0 .. left_count {
				for right in 0 .. right_count {
					if (rows[left] & (u16(1) << right)) == 0 { continue }
					right_vertex := left_count + right
					if states[left] == 0 && states[right_vertex] == 0 { return -1 }
					if states[left] == 0 && states[right_vertex] == -1 {
						states[right_vertex] = 1
						changed = true
					} else if states[right_vertex] == 0 && states[left] == -1 {
						states[left] = 1
						changed = true
					}
				}
			}
		}
	}
	mut forced_in := 0
	for i in 0 .. left_count + right_count { if states[i] == 1 { forced_in++ } }
	mut residual_match := [max_side]i32{}
	forced_in + maximum_matching(left_count, right_count, &rows[0], &states[0], mut residual_match[0])
}

fn canonical_cover(left_count int, right_count int, rows &u16, optimum int) u32 {
	mut states := [max_vertices]i32{}
	for i in 0 .. left_count + right_count { states[i] = -1 }
	for vertex in 0 .. left_count + right_count {
		states[vertex] = 0
		if minimum_completion_size(left_count, right_count, &rows[0], &states[0]) != optimum { states[vertex] = 1 }
	}
	mut result := u32(0)
	for vertex in 0 .. left_count + right_count { if states[vertex] == 1 { result |= u32(1) << vertex } }
	result
}

@[export: 'bipartite_minimum_vertex_cover']
pub fn bipartite_minimum_vertex_cover(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_parseable_input { return -1 }
	unsafe {
		left_value := input[0]
		right_value := input[1]
		if left_value < 0 || left_value > i64(max_side) || right_value < 0 || right_value > i64(max_side) { return -1 }
		left_count := int(left_value)
		right_count := int(right_value)
		if length != usize(left_count + 2) { return -1 }
		right_domain := (u64(1) << right_count) - 1
		mut rows := [max_side]u16{}
		for left in 0 .. left_count {
			row := input[2 + left]
			if row < 0 || (u64(row) & ~right_domain) != 0 { return -1 }
			rows[left] = u16(row)
		}
		mut free_states := [max_vertices]i32{}
		for i in 0 .. left_count + right_count { free_states[i] = -1 }
		mut match_right := [max_side]i32{}
		matching_size := maximum_matching(left_count, right_count, &rows[0], &free_states[0], mut match_right[0])
		optimum := bit_count(alternating_cover(left_count, right_count, &rows[0], &match_right[0]))
		if optimum != matching_size { return -1 }
		return i64(canonical_cover(left_count, right_count, &rows[0], optimum))
	}
}
