const MAX_VALUES: usize = 256;
const MAX_INPUT_LENGTH: usize = 258;

fn distinguishedAncestor(reverse: *const [MAX_VALUES]bool, start: usize) usize {
    var node = start;
    while (node > 0) {
        const parent = node / 2;
        if ((node % 2 == 0 and !reverse[parent]) or (node % 2 == 1 and reverse[parent])) {
            node = parent;
        } else {
            break;
        }
    }
    return node / 2;
}

fn join(values: *[MAX_VALUES]i64, reverse: *[MAX_VALUES]bool, ancestor: usize, node: usize) void {
    if (values[ancestor] < values[node]) {
        const temporary = values[ancestor];
        values[ancestor] = values[node];
        values[node] = temporary;
        reverse[node] = !reverse[node];
    }
}

fn siftDown(values: *[MAX_VALUES]i64, reverse: *[MAX_VALUES]bool, active_size: usize) void {
    var node: usize = if (reverse[0]) 0 else 1;
    if (node >= active_size) return;
    while (2 * node + @as(usize, @intFromBool(reverse[node])) < active_size) {
        node = 2 * node + @as(usize, @intFromBool(reverse[node]));
    }
    while (node != 0) {
        join(values, reverse, 0, node);
        node /= 2;
    }
}

fn execute(input: []const i64) ?i64 {
    if (input.len == 0 or input.len > MAX_INPUT_LENGTH) return null;
    const count64 = input[0];
    if (count64 < 0 or count64 > MAX_VALUES or input.len != @as(usize, @intCast(count64)) + 1) return null;
    const count: usize = @intCast(count64);
    var values: [MAX_VALUES]i64 = @splat(0);
    var reverse: [MAX_VALUES]bool = @splat(false);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -1000 or value > 1000) return null;
        values[index] = value;
    }

    var node = count;
    while (node > 1) {
        node -= 1;
        const ancestor = distinguishedAncestor(&reverse, node);
        join(&values, &reverse, ancestor, node);
    }
    var active_size = count;
    while (active_size > 1) {
        const temporary = values[0];
        values[0] = values[active_size - 1];
        values[active_size - 1] = temporary;
        active_size -= 1;
        siftDown(&values, &reverse, active_size);
    }

    var checksum: i64 = 0;
    for (0..count) |index| checksum += (@as(i64, @intCast(index)) + 1) * (values[index] + 1001);
    return checksum;
}

export fn weak_heapsort(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length == 0 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
