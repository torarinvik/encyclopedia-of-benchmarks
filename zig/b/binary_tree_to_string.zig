const MAX_NODES: usize = 127;

fn decimalLength(value: i64) usize {
    var length: usize = if (value < 0) 1 else 0;
    var magnitude: u64 = @intCast(if (value < 0) -value else value);
    while (true) {
        length += 1;
        magnitude /= 10;
        if (magnitude == 0) return length;
    }
}

fn appendValue(value: i32, output: [*]u8, position: *usize) void {
    var magnitude: u64 = @intCast(if (value < 0) -@as(i64, value) else @as(i64, value));
    var digits: [10]u8 = undefined;
    var count: usize = 0;
    if (value < 0) { output[position.*] = '-'; position.* += 1; }
    while (true) {
        digits[count] = '0' + @as(u8, @intCast(magnitude % 10));
        count += 1;
        magnitude /= 10;
        if (magnitude == 0) break;
    }
    while (count > 0) { count -= 1; output[position.*] = digits[count]; position.* += 1; }
}

fn emitNode(values: [*]const i64, index: usize, output: [*]u8, position: *usize) void {
    const base = 2 + 3 * index;
    const left = values[base + 1];
    const right = values[base + 2];
    appendValue(@intCast(values[base]), output, position);
    if (left >= 0) {
        output[position.*] = '('; position.* += 1;
        emitNode(values, @intCast(left), output, position);
        output[position.*] = ')'; position.* += 1;
    } else if (right >= 0) {
        output[position.*] = '('; position.* += 1;
        output[position.*] = ')'; position.* += 1;
    }
    if (right >= 0) {
        output[position.*] = '('; position.* += 1;
        emitNode(values, @intCast(right), output, position);
        output[position.*] = ')'; position.* += 1;
    }
}

fn validateTree(values: [*]const i64, count: usize, root: usize) bool {
    var parents: [MAX_NODES]u8 = [_]u8{0} ** MAX_NODES;
    var seen: [MAX_NODES]bool = [_]bool{false} ** MAX_NODES;
    var stack: [MAX_NODES]usize = undefined;
    for (0..count) |i| {
        const base = 2 + 3 * i;
        const value = values[base];
        const left = values[base + 1];
        const right = values[base + 2];
        if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
            (left >= 0 and @as(u64, @intCast(left)) >= count) or
            (right >= 0 and @as(u64, @intCast(right)) >= count)) return false;
        if (left >= 0) { const li: usize = @intCast(left); parents[li] += 1; if (parents[li] > 1) return false; }
        if (right >= 0) { const ri: usize = @intCast(right); parents[ri] += 1; if (parents[ri] > 1) return false; }
    }
    for (0..count) |i| if (parents[i] != (if (i == root) 0 else 1)) return false;
    var top: usize = 1;
    var visited: usize = 0;
    stack[0] = root;
    while (top > 0) {
        top -= 1;
        const index = stack[top];
        if (seen[index]) return false;
        seen[index] = true;
        visited += 1;
        const base = 2 + 3 * index;
        const left = values[base + 1];
        const right = values[base + 2];
        if (left >= 0) { stack[top] = @intCast(left); top += 1; }
        if (right >= 0) { stack[top] = @intCast(right); top += 1; }
    }
    return visited == count;
}

export fn binary_tree_to_string(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or values[0] < 0 or values[0] > 127) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 2 + 3 * count) return -1;
    const root_value = values[1];
    if (count == 0) return if (root_value == -1) 0 else -1;
    if (root_value < 0 or @as(u64, @intCast(root_value)) >= count) return -1;
    const root: usize = @intCast(root_value);
    if (!validateTree(values, count, root)) return -1;
    var required = 2 * (count - 1);
    for (0..count) |i| {
        const base = 2 + 3 * i;
        required += decimalLength(values[base]);
        if (values[base + 1] == -1 and values[base + 2] >= 0) required += 2;
    }
    if (output_capacity < required) return -2;
    var position: usize = 0;
    emitNode(values, root, output, &position);
    return @intCast(position);
}
