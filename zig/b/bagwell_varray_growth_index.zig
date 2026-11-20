const Location = struct { pointer_slot: usize, child_base: usize, element_offset: usize };

const LEVEL_HEADERS: usize = 3;

fn level_start(level: usize) usize {
    const starts = [_]usize{ 0, 64, 320 };
    return starts[level];
}

fn locate(level: usize, index: usize) Location {
    const value_start = level_start(level);
    const side: usize = if (level == 0) 8 else if (level == 1) 16 else 32;
    const pointer_start: usize = if (level == 0) 0 else if (level == 1) 8 else 24;
    const relative = index - value_start;
    const child = relative / side;
    return .{
        .pointer_slot = pointer_start + child,
        .child_base = value_start + child * side,
        .element_offset = relative % side,
    };
}

fn find_level(index: usize, current_header: usize, previous_header: *const [LEVEL_HEADERS]i64) i64 {
    var level: i64 = @intCast(current_header);
    while (level >= 0 and index < level_start(@intCast(level))) {
        level = previous_header.*[@intCast(level)];
    }
    return level;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn bagwell_varray_growth_index(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 580) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 0 or n_value > 321 or q_value < 0 or q_value > 256) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if ((n == 0 and q != 0) or length != 2 + n + q) return -1;
    const query_start = 2 + n;
    for (0..q) |j| {
        const index = input[query_start + j];
        if (index < 0 or index >= n_value) return -1;
    }

    var data: [352]i64 = @splat(0);
    var pointers: [56]i64 = @splat(-1);
    var previous_header: [LEVEL_HEADERS]i64 = @splat(-1);
    var current_header: usize = 0;
    for (0..n) |index| {
        if (index == 64 or index == 320) {
            const next_header = current_header + 1;
            previous_header[next_header] = @intCast(current_header);
            current_header = next_header;
        }
        const location = locate(current_header, index);
        if (pointers[location.pointer_slot] == -1)
            pointers[location.pointer_slot] = @intCast(location.child_base);
        if (pointers[location.pointer_slot] != @as(i64, @intCast(location.child_base))
            or location.child_base + location.element_offset >= data.len) return -1;
        data[@as(usize, @intCast(pointers[location.pointer_slot])) + location.element_offset] = input[2 + index];
    }

    const output_bytes = 8 * (q + 1);
    if (output == null or capacity < output_bytes) return -2;
    putI64Le(output, 0, q_value);
    for (0..q) |j| {
        const index: usize = @intCast(input[query_start + j]);
        const level = find_level(index, current_header, &previous_header);
        const location = locate(@intCast(level), index);
        const base: usize = @intCast(pointers[location.pointer_slot]);
        putI64Le(output, 8 * (j + 1), data[base + location.element_offset]);
    }
    return @intCast(output_bytes);
}
