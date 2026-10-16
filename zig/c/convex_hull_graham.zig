const MAX_POINTS: usize = 64;

fn cross(a: usize, b: usize, c: usize, values: []const i64) i64 {
    const ax = values[2*a]; const ay = values[2*a+1];
    const bx = values[2*b]; const by = values[2*b+1];
    const cx = values[2*c]; const cy = values[2*c+1];
    return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax);
}

fn orientation(a: usize, b: usize, c: usize, values: []const i64) i32 {
    const turn = cross(a, b, c, values);
    if (turn < 0) return 1;
    if (turn > 0) return -1;
    return 0;
}

fn sortIndices(items: []usize, scratch: []usize, values: []const i64) void {
    if (items.len < 2) return;
    const middle = items.len / 2;
    sortIndices(items[0..middle], scratch[0..middle], values);
    sortIndices(items[middle..], scratch[middle..], values);
    var left: usize = 0;
    var right: usize = middle;
    var out: usize = 0;
    while (left < middle and right < items.len) {
        if (values[2*items[right]] < values[2*items[left]]) {
            scratch[out] = items[right]; right += 1;
        } else {
            scratch[out] = items[left]; left += 1;
        }
        out += 1;
    }
    while (left < middle) : (left += 1) { scratch[out] = items[left]; out += 1; }
    while (right < items.len) : (right += 1) { scratch[out] = items[right]; out += 1; }
    @memcpy(items, scratch[0..items.len]);
}

fn putIndex(output: [*c]u8, position: usize, id: usize) void {
    const value: u32 = @intCast(id);
    for (0..4) |byte| output[4*position+byte] = @truncate(value >> @intCast(8*byte));
}

export fn convex_hull_graham(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length % 2 != 0 or length > 2*MAX_POINTS) return -1;
    const count = length / 2;
    if (count < 3 or count > MAX_POINTS) return -1;
    const values = input[0..length];
    for (values) |coordinate| {
        if (coordinate < -2000 or coordinate > 2000) return -1;
    }

    var order_storage: [MAX_POINTS]usize = undefined;
    var scratch_storage: [MAX_POINTS]usize = undefined;
    var upper: [MAX_POINTS]usize = undefined;
    var lower: [MAX_POINTS]usize = undefined;
    const order = order_storage[0..count];
    const scratch = scratch_storage[0..count];
    for (order, 0..) |*item, index| item.* = index;
    sortIndices(order, scratch, values);
    for (1..count) |index|
        if (values[2*order[index-1]] == values[2*order[index]]) return -1;
    for (1..(count-1)) |index|
        if (cross(order[0], order[index], order[count-1], values) == 0) return -1;

    var upper_count: usize = 1;
    var lower_count: usize = 1;
    upper[0] = 0;
    lower[0] = 0;
    for (1..count) |index| {
        const turn = orientation(order[0], order[index], order[count-1], values);
        if (index == count-1 or turn != -1) {
            while (upper_count >= 2 and orientation(order[upper[upper_count-2]],
                order[upper[upper_count-1]], order[index], values) == -1) upper_count -= 1;
            upper[upper_count] = index;
            upper_count += 1;
        }
        if (index == count-1 or turn != 1) {
            while (lower_count >= 2 and orientation(order[lower[lower_count-2]],
                order[lower[lower_count-1]], order[index], values) == 1) lower_count -= 1;
            lower[lower_count] = index;
            lower_count += 1;
        }
    }
    const hull_count = upper_count - 2 + lower_count;
    if (output == null or capacity < 4*hull_count) return -2;
    var written: usize = 0;
    for (1..(upper_count-1)) |index| { putIndex(output, written, order[upper[index]]); written += 1; }
    var index = lower_count;
    while (index > 0) { index -= 1; putIndex(output, written, order[lower[index]]); written += 1; }
    return @intCast(hull_count);
}
