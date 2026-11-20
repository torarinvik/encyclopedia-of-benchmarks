package succinct_bp_pioneer_match_index

import "core:c"

MAX_PAIRS :: 32
MAX_BITS :: 64
MAX_INPUT :: 66
MAX_OUTPUT :: 520
BLOCK_SIZE :: 8
BLOCK_COUNT :: 8
BASE_BITS :: 16
MAX_LEVELS :: 3
MISSING :: u8(255)

Index :: struct {
    length: int,
    bits: [MAX_BITS]u8,
    local_mate: [MAX_BITS]u8,
    depth: [MAX_BITS + 1]i16,
    open_pioneers: [MAX_BITS]u8,
    open_pioneer_count: int,
    close_pioneers: [MAX_BITS]u8,
    close_pioneer_count: int,
    family: [MAX_BITS]u8,
    family_rank: [MAX_BITS]u8,
    family_count: int,
    group_source: [MAX_BITS]u8,
    group_target: [MAX_BITS]u8,
    group_depth: [MAX_BITS]i16,
    group_count: int,
    open_positions: [MAX_BITS]u8,
    open_groups: [MAX_BITS]u8,
    open_count: int,
    close_positions: [MAX_BITS]u8,
    close_groups: [MAX_BITS]u8,
    close_count: int,
}

Context :: struct { levels: [MAX_LEVELS]Index }

ensure_group :: proc(index: ^Index, source, target: int, depth: i16) -> int {
    for group in 0..<index.group_count {
        if int(index.group_source[group]) == source && int(index.group_target[group]) == target && index.group_depth[group] == depth {
            return group
        }
    }
    group := index.group_count
    index.group_source[group] = u8(source)
    index.group_target[group] = u8(target)
    index.group_depth[group] = depth
    index.group_count += 1
    return group
}

find_group :: proc(index: ^Index, source, target: int, depth: i16) -> int {
    for group in 0..<index.group_count {
        if int(index.group_source[group]) == source && int(index.group_target[group]) == target && index.group_depth[group] == depth {
            return group
        }
    }
    return -1
}

build :: proc(context: ^Context, level: int, bits: []u8) -> bool {
    if level >= MAX_LEVELS || len(bits) > MAX_BITS do return false
    index := &context.levels[level]
    index.length = len(bits)
    stack: [MAX_BITS]u8
    mates: [MAX_BITS]u8
    top := 0
    for position in 0..<len(bits) {
        bit := bits[position]
        index.bits[position] = bit
        index.local_mate[position] = MISSING
        index.family_rank[position] = MISSING
        if bit == 1 {
            index.depth[position+1] = index.depth[position] + 1
            stack[top] = u8(position)
            top += 1
        } else {
            index.depth[position+1] = index.depth[position] - 1
            top -= 1
            opening := int(stack[top])
            mates[opening] = u8(position)
            mates[position] = u8(opening)
        }
    }
    if len(bits) <= BASE_BITS {
        for position in 0..<len(bits) { index.local_mate[position] = mates[position] }
        return true
    }

    far: [MAX_BITS]bool
    for position in 0..<len(bits) {
        partner := int(mates[position])
        if partner/BLOCK_SIZE != position/BLOCK_SIZE {
            far[position] = true
        } else {
            index.local_mate[position] = mates[position]
        }
    }
    seen_open: [BLOCK_COUNT]bool
    last_open_target: [BLOCK_COUNT]u8
    for position in 0..<len(bits) {
        if bits[position] == 1 && far[position] {
            block := position / BLOCK_SIZE
            target := int(mates[position]) / BLOCK_SIZE
            if !seen_open[block] || int(last_open_target[block]) != target {
                index.open_pioneers[index.open_pioneer_count] = u8(position)
                index.open_pioneer_count += 1
            }
            seen_open[block] = true
            last_open_target[block] = u8(target)
        }
    }
    seen_close: [BLOCK_COUNT]bool
    last_close_target: [BLOCK_COUNT]u8
    for step in 0..<len(bits) {
        position := len(bits) - 1 - step
        if bits[position] == 0 && far[position] {
            block := position / BLOCK_SIZE
            target := int(mates[position]) / BLOCK_SIZE
            if !seen_close[block] || int(last_close_target[block]) != target {
                index.close_pioneers[index.close_pioneer_count] = u8(position)
                index.close_pioneer_count += 1
            }
            seen_close[block] = true
            last_close_target[block] = u8(target)
        }
    }

    in_family: [MAX_BITS]bool
    for i in 0..<index.open_pioneer_count {
        position := int(index.open_pioneers[i])
        in_family[position] = true
        in_family[int(mates[position])] = true
    }
    for i in 0..<index.close_pioneer_count {
        position := int(index.close_pioneers[i])
        in_family[position] = true
        in_family[int(mates[position])] = true
    }
    for position in 0..<len(bits) {
        if in_family[position] {
            index.family_rank[position] = u8(index.family_count)
            index.family[index.family_count] = u8(position)
            index.family_count += 1
        }
    }

    for position in 0..<len(bits) {
        if !far[position] do continue
        source := position / BLOCK_SIZE
        target := int(mates[position]) / BLOCK_SIZE
        depth := index.depth[position]
        if bits[position] == 0 { depth = index.depth[position+1] }
        group := ensure_group(index, source, target, depth)
        if bits[position] == 1 {
            index.open_positions[index.open_count] = u8(position)
            index.open_groups[index.open_count] = u8(group)
            index.open_count += 1
        } else {
            index.close_positions[index.close_count] = u8(position)
            index.close_groups[index.close_count] = u8(group)
            index.close_count += 1
        }
    }

    if index.family_count == 0 do return true
    child_bits: [MAX_BITS]u8
    for rank in 0..<index.family_count { child_bits[rank] = bits[int(index.family[rank])] }
    return build(context, level+1, child_bits[:index.family_count])
}

rank_position :: proc(index: ^Index, group, position: int, openings: bool) -> int {
    rank := 0
    if openings {
        for i in 0..<index.open_count {
            if int(index.open_groups[i]) == group {
                if int(index.open_positions[i]) == position { return rank }
                rank += 1
            }
        }
    } else {
        for i in 0..<index.close_count {
            if int(index.close_groups[i]) == group {
                if int(index.close_positions[i]) == position { return rank }
                rank += 1
            }
        }
    }
    return -1
}

select_position :: proc(index: ^Index, group, rank: int, openings: bool) -> int {
    current := 0
    if openings {
        for i in 0..<index.open_count {
            if int(index.open_groups[i]) == group {
                if current == rank { return int(index.open_positions[i]) }
                current += 1
            }
        }
    } else {
        for i in 0..<index.close_count {
            if int(index.close_groups[i]) == group {
                if current == rank { return int(index.close_positions[i]) }
                current += 1
            }
        }
    }
    return -1
}

matching :: proc(context: ^Context, level, position: int) -> int {
    index := &context.levels[level]
    if index.local_mate[position] != MISSING { return int(index.local_mate[position]) }
    source := position / BLOCK_SIZE
    if index.bits[position] == 1 {
        pioneer := -1
        for i in 0..<index.open_pioneer_count {
            candidate := int(index.open_pioneers[i])
            if candidate/BLOCK_SIZE == source && candidate <= position { pioneer = candidate }
        }
        if pioneer < 0 do return -1
        child_position := int(index.family_rank[pioneer])
        child_mate := matching(context, level+1, child_position)
        if child_mate < 0 do return -1
        anchor := int(index.family[child_mate])
        target := anchor / BLOCK_SIZE
        depth := index.depth[position]
        group := find_group(index, source, target, depth)
        opposite := find_group(index, target, source, depth)
        if group < 0 || opposite < 0 do return -1
        rank := rank_position(index, group, position, true)
        if rank < 0 do return -1
        return select_position(index, opposite, rank, false)
    }
    pioneer := -1
    for i in 0..<index.close_pioneer_count {
        candidate := int(index.close_pioneers[i])
        if candidate/BLOCK_SIZE == source && candidate >= position && (pioneer < 0 || candidate < pioneer) { pioneer = candidate }
    }
    if pioneer < 0 do return -1
    child_position := int(index.family_rank[pioneer])
    child_mate := matching(context, level+1, child_position)
    if child_mate < 0 do return -1
    anchor := int(index.family[child_mate])
    target := anchor / BLOCK_SIZE
    depth := index.depth[position+1]
    group := find_group(index, source, target, depth)
    opposite := find_group(index, target, source, depth)
    if group < 0 || opposite < 0 do return -1
    rank := rank_position(index, group, position, false)
    if rank < 0 do return -1
    return select_position(index, opposite, rank, true)
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte in 0..<8 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
succinct_bp_pioneer_match_index :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    pairs0 := input[0]
    if pairs0 < 1 || pairs0 > MAX_PAIRS do return -1
    pairs := int(pairs0)
    bit_count := 2*pairs
    if int(length) != 1+bit_count do return -1
    bits: [MAX_BITS]u8
    balance := 0
    for position in 0..<bit_count {
        bit := input[position+1]
        if bit != 0 && bit != 1 do return -1
        bits[position] = u8(bit)
        if bit == 1 { balance += 1 } else { balance -= 1 }
        if balance < 0 do return -1
    }
    if balance != 0 do return -1
    required := c.size_t(length * 8)
    if output == nil || capacity < required || required > MAX_OUTPUT do return -2
    context: Context
    if !build(&context, 0, bits[:bit_count]) do return -1
    answers: [MAX_BITS]int
    for position in 0..<bit_count {
        answers[position] = matching(&context, 0, position)
        if answers[position] < 0 do return -1
    }
    put_i64(output, 0, i64(bit_count))
    for position in 0..<bit_count { put_i64(output, 8*(position+1), i64(answers[position])) }
    return i64(required)
}
