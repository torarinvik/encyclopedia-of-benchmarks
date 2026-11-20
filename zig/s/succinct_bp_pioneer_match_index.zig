const MAX_PAIRS: usize = 32;
const MAX_BITS: usize = 2 * MAX_PAIRS;
const MAX_INPUT: usize = 1 + MAX_BITS + 1;
const MAX_OUTPUT: usize = 8 * (1 + MAX_BITS);
const BLOCK_SIZE: usize = 8;
const BLOCK_COUNT: usize = MAX_BITS / BLOCK_SIZE;
const BASE_BITS: usize = 16;
const MAX_LEVELS: usize = 3;
const MISSING: u8 = 255;

const Index = struct {
    length: usize = 0,
    bits: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    local_mate: [MAX_BITS]u8 = [_]u8{MISSING} ** MAX_BITS,
    depth: [MAX_BITS + 1]u8 = [_]u8{0} ** (MAX_BITS + 1),
    open_pioneers: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    open_pioneer_count: usize = 0,
    close_pioneers: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    close_pioneer_count: usize = 0,
    family: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    family_rank: [MAX_BITS]u8 = [_]u8{MISSING} ** MAX_BITS,
    family_count: usize = 0,
    group_source: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    group_target: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    group_depth: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    group_count: usize = 0,
    open_positions: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    open_groups: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    open_count: usize = 0,
    close_positions: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    close_groups: [MAX_BITS]u8 = [_]u8{0} ** MAX_BITS,
    close_count: usize = 0,
};

const Context = struct { levels: [MAX_LEVELS]Index = [_]Index{.{}} ** MAX_LEVELS };

fn ensureGroup(index: *Index, source: usize, target: usize, depth: u8) usize {
    for (0..index.group_count) |group| {
        if (index.group_source[group] == source and index.group_target[group] == target and
            index.group_depth[group] == depth) return group;
    }
    const group = index.group_count;
    index.group_source[group] = @intCast(source);
    index.group_target[group] = @intCast(target);
    index.group_depth[group] = depth;
    index.group_count += 1;
    return group;
}

fn findGroup(index: *const Index, source: usize, target: usize, depth: u8) ?usize {
    for (0..index.group_count) |group| {
        if (index.group_source[group] == source and index.group_target[group] == target and
            index.group_depth[group] == depth) return group;
    }
    return null;
}

fn build(context: *Context, level: usize, bits: []const u8) bool {
    if (level >= MAX_LEVELS or bits.len > MAX_BITS) return false;
    var index = &context.levels[level];
    index.length = bits.len;
    var stack: [MAX_BITS]u8 = undefined;
    var mates: [MAX_BITS]u8 = undefined;
    var top: usize = 0;
    for (bits, 0..) |bit, position| {
        index.bits[position] = bit;
        index.local_mate[position] = MISSING;
        index.family_rank[position] = MISSING;
        index.depth[position + 1] = if (bit == 1) index.depth[position] + 1 else index.depth[position] - 1;
        if (bit == 1) {
            stack[top] = @intCast(position);
            top += 1;
        } else {
            top -= 1;
            const opening = stack[top];
            mates[opening] = @intCast(position);
            mates[position] = opening;
        }
    }
    if (bits.len <= BASE_BITS) {
        for (0..bits.len) |position| index.local_mate[position] = mates[position];
        return true;
    }

    var far = [_]bool{false} ** MAX_BITS;
    for (0..bits.len) |position| {
        const partner: usize = mates[position];
        if (partner / BLOCK_SIZE != position / BLOCK_SIZE) {
            far[position] = true;
        } else {
            index.local_mate[position] = mates[position];
        }
    }
    var seen_open = [_]bool{false} ** BLOCK_COUNT;
    var last_open_target = [_]u8{0} ** BLOCK_COUNT;
    for (0..bits.len) |position| {
        if (bits[position] == 1 and far[position]) {
            const block = position / BLOCK_SIZE;
            const target: usize = mates[position] / BLOCK_SIZE;
            if (!seen_open[block] or last_open_target[block] != target) {
                index.open_pioneers[index.open_pioneer_count] = @intCast(position);
                index.open_pioneer_count += 1;
            }
            seen_open[block] = true;
            last_open_target[block] = @intCast(target);
        }
    }
    var seen_close = [_]bool{false} ** BLOCK_COUNT;
    var last_close_target = [_]u8{0} ** BLOCK_COUNT;
    var cursor = bits.len;
    while (cursor > 0) {
        cursor -= 1;
        const position = cursor;
        if (bits[position] == 0 and far[position]) {
            const block = position / BLOCK_SIZE;
            const target: usize = mates[position] / BLOCK_SIZE;
            if (!seen_close[block] or last_close_target[block] != target) {
                index.close_pioneers[index.close_pioneer_count] = @intCast(position);
                index.close_pioneer_count += 1;
            }
            seen_close[block] = true;
            last_close_target[block] = @intCast(target);
        }
    }

    var in_family = [_]bool{false} ** MAX_BITS;
    for (0..index.open_pioneer_count) |i| {
        const position: usize = index.open_pioneers[i];
        in_family[position] = true;
        in_family[mates[position]] = true;
    }
    for (0..index.close_pioneer_count) |i| {
        const position: usize = index.close_pioneers[i];
        in_family[position] = true;
        in_family[mates[position]] = true;
    }
    for (0..bits.len) |position| {
        if (in_family[position]) {
            index.family_rank[position] = @intCast(index.family_count);
            index.family[index.family_count] = @intCast(position);
            index.family_count += 1;
        }
    }

    for (0..bits.len) |position| {
        if (!far[position]) continue;
        const source = position / BLOCK_SIZE;
        const target: usize = mates[position] / BLOCK_SIZE;
        const depth = if (bits[position] == 1) index.depth[position] else index.depth[position + 1];
        const group = ensureGroup(index, source, target, depth);
        if (bits[position] == 1) {
            index.open_positions[index.open_count] = @intCast(position);
            index.open_groups[index.open_count] = @intCast(group);
            index.open_count += 1;
        } else {
            index.close_positions[index.close_count] = @intCast(position);
            index.close_groups[index.close_count] = @intCast(group);
            index.close_count += 1;
        }
    }

    if (index.family_count == 0) return true;
    var child_bits: [MAX_BITS]u8 = undefined;
    for (0..index.family_count) |rank| child_bits[rank] = bits[index.family[rank]];
    return build(context, level + 1, child_bits[0..index.family_count]);
}

fn rankPosition(index: *const Index, group: usize, position: usize, openings: bool) ?usize {
    var rank: usize = 0;
    if (openings) {
        for (0..index.open_count) |i| {
            if (index.open_groups[i] == group) {
                if (index.open_positions[i] == position) return rank;
                rank += 1;
            }
        }
    } else {
        for (0..index.close_count) |i| {
            if (index.close_groups[i] == group) {
                if (index.close_positions[i] == position) return rank;
                rank += 1;
            }
        }
    }
    return null;
}

fn selectPosition(index: *const Index, group: usize, rank: usize, openings: bool) ?usize {
    var current: usize = 0;
    if (openings) {
        for (0..index.open_count) |i| {
            if (index.open_groups[i] == group) {
                if (current == rank) return index.open_positions[i];
                current += 1;
            }
        }
    } else {
        for (0..index.close_count) |i| {
            if (index.close_groups[i] == group) {
                if (current == rank) return index.close_positions[i];
                current += 1;
            }
        }
    }
    return null;
}

fn matching(context: *const Context, level: usize, position: usize) ?usize {
    const index = &context.levels[level];
    if (index.local_mate[position] != MISSING) return index.local_mate[position];
    const source = position / BLOCK_SIZE;
    if (index.bits[position] == 1) {
        var pioneer: ?usize = null;
        for (0..index.open_pioneer_count) |i| {
            const candidate: usize = index.open_pioneers[i];
            if (candidate / BLOCK_SIZE == source and candidate <= position) pioneer = candidate;
        }
        const p = pioneer orelse return null;
        const child_position = index.family_rank[p];
        const child_mate = tryMatch(context, level + 1, child_position) orelse return null;
        const anchor: usize = index.family[child_mate];
        const target = anchor / BLOCK_SIZE;
        const depth = index.depth[position];
        const group = findGroup(index, source, target, depth) orelse return null;
        const opposite = findGroup(index, target, source, depth) orelse return null;
        const rank = rankPosition(index, group, position, true) orelse return null;
        return selectPosition(index, opposite, rank, false);
    }
    var pioneer: ?usize = null;
    for (0..index.close_pioneer_count) |i| {
        const candidate: usize = index.close_pioneers[i];
        if (candidate / BLOCK_SIZE == source and candidate >= position) {
            if (pioneer == null or candidate < pioneer.?) pioneer = candidate;
        }
    }
    const p = pioneer orelse return null;
    const child_position = index.family_rank[p];
    const child_mate = tryMatch(context, level + 1, child_position) orelse return null;
    const anchor: usize = index.family[child_mate];
    const target = anchor / BLOCK_SIZE;
    const depth = index.depth[position + 1];
    const group = findGroup(index, source, target, depth) orelse return null;
    const opposite = findGroup(index, target, source, depth) orelse return null;
    const rank = rankPosition(index, group, position, false) orelse return null;
    return selectPosition(index, opposite, rank, true);
}

fn tryMatch(context: *const Context, level: usize, position: usize) ?usize {
    return matching(context, level, position);
}

fn put(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn succinct_bp_pioneer_match_index(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const pairs0 = input[0];
    if (pairs0 < 1 or pairs0 > MAX_PAIRS) return -1;
    const pairs: usize = @intCast(pairs0);
    const bit_count = pairs * 2;
    if (length != 1 + bit_count) return -1;
    var bits: [MAX_BITS]u8 = undefined;
    var balance: isize = 0;
    for (0..bit_count) |position| {
        const bit = input[position + 1];
        if (bit != 0 and bit != 1) return -1;
        bits[position] = @intCast(bit);
        if (bit == 1) balance += 1 else balance -= 1;
        if (balance < 0) return -1;
    }
    if (balance != 0) return -1;
    const required = length * 8;
    if (output == null or capacity < required or required > MAX_OUTPUT) return -2;

    var context = Context{};
    if (!build(&context, 0, bits[0..bit_count])) return -1;
    var answers: [MAX_BITS]usize = undefined;
    for (0..bit_count) |position| answers[position] = matching(&context, 0, position) orelse return -1;
    put(output, 0, @intCast(bit_count));
    for (0..bit_count) |position| put(output, (position + 1) * 8, @intCast(answers[position]));
    return @intCast(required);
}
