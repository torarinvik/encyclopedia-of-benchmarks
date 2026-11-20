module succinct_bp_pioneer_match_index

const max_pairs = 32
const max_bits = 64
const max_input = 66
const max_output = 520
const block_size = 8
const block_count = 8
const base_bits = 16
const max_levels = 3
const missing = u8(255)

struct Index {
mut:
	length int
	bits [max_bits]u8
	local_mate [max_bits]u8
	depth [max_bits + 1]i16
	open_pioneers [max_bits]u8
	open_pioneer_count int
	close_pioneers [max_bits]u8
	close_pioneer_count int
	family [max_bits]u8
	family_rank [max_bits]u8
	family_count int
	group_source [max_bits]u8
	group_target [max_bits]u8
	group_depth [max_bits]i16
	group_count int
	open_positions [max_bits]u8
	open_groups [max_bits]u8
	open_count int
	close_positions [max_bits]u8
	close_groups [max_bits]u8
	close_count int
}

struct Context {
mut:
	levels [max_levels]Index
}

fn ensure_group(mut index &Index, source int, target int, depth i16) int {
	for group in 0 .. index.group_count {
		if int(index.group_source[group]) == source && int(index.group_target[group]) == target
			&& index.group_depth[group] == depth {
			return group
		}
	}
	group := index.group_count
	index.group_source[group] = u8(source)
	index.group_target[group] = u8(target)
	index.group_depth[group] = depth
	index.group_count++
	return group
}

fn find_group(index &Index, source int, target int, depth i16) int {
	for group in 0 .. index.group_count {
		if int(index.group_source[group]) == source && int(index.group_target[group]) == target
			&& index.group_depth[group] == depth {
			return group
		}
	}
	return -1
}

fn build(mut context &Context, level int, bits []u8) bool {
	if level >= max_levels || bits.len > max_bits {
		return false
	}
	mut index := &context.levels[level]
	index.length = bits.len
	mut stack := [max_bits]u8{}
	mut mates := [max_bits]u8{}
	mut top := 0
	for position in 0 .. bits.len {
		bit := bits[position]
		index.bits[position] = bit
		index.local_mate[position] = missing
		index.family_rank[position] = missing
		if bit == 1 {
			index.depth[position + 1] = index.depth[position] + 1
			stack[top] = u8(position)
			top++
		} else {
			index.depth[position + 1] = index.depth[position] - 1
			top--
			opening := int(stack[top])
			mates[opening] = u8(position)
			mates[position] = u8(opening)
		}
	}
	if bits.len <= base_bits {
		for position in 0 .. bits.len {
			index.local_mate[position] = mates[position]
		}
		return true
	}

	mut far := [max_bits]bool{}
	for position in 0 .. bits.len {
		partner := int(mates[position])
		if partner / block_size != position / block_size {
			far[position] = true
		} else {
			index.local_mate[position] = mates[position]
		}
	}
	mut seen_open := [block_count]bool{}
	mut last_open_target := [block_count]u8{}
	for position in 0 .. bits.len {
		if bits[position] == 1 && far[position] {
			block := position / block_size
			target := int(mates[position]) / block_size
			if !seen_open[block] || int(last_open_target[block]) != target {
				index.open_pioneers[index.open_pioneer_count] = u8(position)
				index.open_pioneer_count++
			}
			seen_open[block] = true
			last_open_target[block] = u8(target)
		}
	}
	mut seen_close := [block_count]bool{}
	mut last_close_target := [block_count]u8{}
	for step in 0 .. bits.len {
		position := bits.len - 1 - step
		if bits[position] == 0 && far[position] {
			block := position / block_size
			target := int(mates[position]) / block_size
			if !seen_close[block] || int(last_close_target[block]) != target {
				index.close_pioneers[index.close_pioneer_count] = u8(position)
				index.close_pioneer_count++
			}
			seen_close[block] = true
			last_close_target[block] = u8(target)
		}
	}

	mut in_family := [max_bits]bool{}
	for i in 0 .. index.open_pioneer_count {
		position := int(index.open_pioneers[i])
		in_family[position] = true
		in_family[int(mates[position])] = true
	}
	for i in 0 .. index.close_pioneer_count {
		position := int(index.close_pioneers[i])
		in_family[position] = true
		in_family[int(mates[position])] = true
	}
	for position in 0 .. bits.len {
		if in_family[position] {
			index.family_rank[position] = u8(index.family_count)
			index.family[index.family_count] = u8(position)
			index.family_count++
		}
	}

	for position in 0 .. bits.len {
		if !far[position] {
			continue
		}
		source := position / block_size
		target := int(mates[position]) / block_size
		mut depth := index.depth[position]
		if bits[position] == 0 {
			depth = index.depth[position + 1]
		}
		group := ensure_group(mut index, source, target, depth)
		if bits[position] == 1 {
			index.open_positions[index.open_count] = u8(position)
			index.open_groups[index.open_count] = u8(group)
			index.open_count++
		} else {
			index.close_positions[index.close_count] = u8(position)
			index.close_groups[index.close_count] = u8(group)
			index.close_count++
		}
	}

	if index.family_count == 0 {
		return true
	}
	mut child_bits := [max_bits]u8{}
	for rank in 0 .. index.family_count {
		child_bits[rank] = bits[int(index.family[rank])]
	}
	return build(mut context, level + 1, child_bits[..index.family_count])
}

fn rank_position(index &Index, group int, position int, openings bool) int {
	mut rank := 0
	if openings {
		for i in 0 .. index.open_count {
			if int(index.open_groups[i]) == group {
				if int(index.open_positions[i]) == position {
					return rank
				}
				rank++
			}
		}
	} else {
		for i in 0 .. index.close_count {
			if int(index.close_groups[i]) == group {
				if int(index.close_positions[i]) == position {
					return rank
				}
				rank++
			}
		}
	}
	return -1
}

fn select_position(index &Index, group int, rank int, openings bool) int {
	mut current := 0
	if openings {
		for i in 0 .. index.open_count {
			if int(index.open_groups[i]) == group {
				if current == rank {
					return int(index.open_positions[i])
				}
				current++
			}
		}
	} else {
		for i in 0 .. index.close_count {
			if int(index.close_groups[i]) == group {
				if current == rank {
					return int(index.close_positions[i])
				}
				current++
			}
		}
	}
	return -1
}

fn matching(context &Context, level int, position int) int {
	index := &context.levels[level]
	if index.local_mate[position] != missing {
		return int(index.local_mate[position])
	}
	source := position / block_size
	if index.bits[position] == 1 {
		mut pioneer := -1
		for i in 0 .. index.open_pioneer_count {
			candidate := int(index.open_pioneers[i])
			if candidate / block_size == source && candidate <= position {
				pioneer = candidate
			}
		}
		if pioneer < 0 {
			return -1
		}
		child_position := int(index.family_rank[pioneer])
		child_mate := matching(context, level + 1, child_position)
		if child_mate < 0 {
			return -1
		}
		anchor := int(index.family[child_mate])
		target := anchor / block_size
		depth := index.depth[position]
		group := find_group(index, source, target, depth)
		opposite := find_group(index, target, source, depth)
		if group < 0 || opposite < 0 {
			return -1
		}
		rank := rank_position(index, group, position, true)
		if rank < 0 {
			return -1
		}
		return select_position(index, opposite, rank, false)
	}
	mut pioneer := -1
	for i in 0 .. index.close_pioneer_count {
		candidate := int(index.close_pioneers[i])
		if candidate / block_size == source && candidate >= position {
			if pioneer < 0 || candidate < pioneer {
				pioneer = candidate
			}
		}
	}
	if pioneer < 0 {
		return -1
	}
	child_position := int(index.family_rank[pioneer])
	child_mate := matching(context, level + 1, child_position)
	if child_mate < 0 {
		return -1
	}
	anchor := int(index.family[child_mate])
	target := anchor / block_size
	depth := index.depth[position + 1]
	group := find_group(index, source, target, depth)
	opposite := find_group(index, target, source, depth)
	if group < 0 || opposite < 0 {
		return -1
	}
	rank := rank_position(index, group, position, false)
	if rank < 0 {
		return -1
	}
	return select_position(index, opposite, rank, true)
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'succinct_bp_pioneer_match_index']
pub fn succinct_bp_pioneer_match_index(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > max_input {
		return -1
	}
	pairs0 := unsafe { input[0] }
	if pairs0 < 1 || pairs0 > max_pairs {
		return -1
	}
	bit_count := 2 * int(pairs0)
	if length != usize(1 + bit_count) {
		return -1
	}
	mut bits := [max_bits]u8{}
	mut balance := 0
	for position in 0 .. bit_count {
		bit := unsafe { input[position + 1] }
		if bit != 0 && bit != 1 {
			return -1
		}
		bits[position] = u8(bit)
		if bit == 1 {
			balance++
		} else {
			balance--
		}
		if balance < 0 {
			return -1
		}
	}
	if balance != 0 {
		return -1
	}
	required := length * 8
	if output == nil || capacity < required || required > max_output {
		return -2
	}
	mut context := Context{}
	if !build(mut context, 0, bits[..bit_count]) {
		return -1
	}
	mut answers := [max_bits]int{}
	for position in 0 .. bit_count {
		answers[position] = matching(context, 0, position)
		if answers[position] < 0 {
			return -1
		}
	}
	put_i64(mut output, 0, i64(bit_count))
	for position in 0 .. bit_count {
		put_i64(mut output, 8 * (position + 1), i64(answers[position]))
	}
	return i64(required)
}
